class ExpaRdSync
  attr_accessor :rd_identifiers
  attr_accessor :rd_tags


  def initialize
    self.rd_identifiers = {
        :test => 'test', #This is the identifier that should always be used during test phase
        :form_podio_offline => 'form-podio-offline',
        :expa => 'expa',
        :open => 'open',
        :landing_0 => 'completou-cadastro',
        :landing_1 => 'form-video-suporte-aiesec',
        :landing_2 => '15-dicas-para-planejar-sua-viagem-sem-imprevistos',
        :in_progress => 'in_progress',
        :rejected => 'rejected',
        :accepted => 'accepted',
        :approved => 'approved'
    }

    self.rd_tags = {
        :gip => 'GIP',
        :gcdp => 'GCDP'
    }
  end

  def list_people
    setup_expa_api
    params = {'per_page' => 100}
    total_items = EXPA::People.total_items
    total_pages = total_items / params['per_page']
    total_pages = total_pages + 1 if total_items % params['per_page'] > 0

    for i in 1...total_pages
      params['page'] = i
      people = EXPA::People.list_by_param(params)
      people.each do |xp_person|
        update_db_peoples(xp_person)
      end
    end
  end

  def list_applications
    setup_expa_api
    params = {'per_page' => 100}
    total_items = EXPA::Applicaations.total_items
    total_pages = total_items / params['per_page']
    total_pages = total_pages + 1 if total_items % params['per_page'] > 0

    for i in 1...total_pages
      params['page'] = i
      applications = EXPA::Applications.list_by_param(params)
      applications.each do |xp_application|
        update_db_applications(xp_application)
      end
    end
  end

  def list_open
    setup_expa_api
    time = Time.now - 10*60 # 10 minutes windows
    people = EXPA::People.list_everyone_created_after(time)
    people.each do |xp_person|
      person = ExpaPerson.find_by_xp_id(xp_person.id)
      if ExpaPerson.exists?(person)
        update_db_peoples(xp_person)
      else
        person = update_db_peoples(xp_person)
        send_to_rd(person, nil, self.rd_identifiers[:open], nil)
      end
    end
  end

  def update_podio
    Podio.setup(:api_key => ENV['PODIO_API_KEY'], :api_secret => ENV['PODIO_API_SECRET'])
    Podio.client.authenticate_with_credentials(ENV['PODIO_USERNAME'], ENV['PODIO_PASSWORD'])

    study_level = DigitalTransformation.study_level
    entities = DigitalTransformation.hash_entities_podio
    universities = DigitalTransformation.hash_universities_podio
    courses = DigitalTransformation.hash_courses_podio

    people = ExpaPerson.where.not(control_podio: nil).order(xp_updated_at: :desc)
    people.each do |person|
      if JSON.parse(person.control_podio).key?('podio_status') && JSON.parse(person.control_podio)['podio_status'] == 'lead_decidido'
        if person.interested_program == 'global_volunteer'
          podio_app_decided_leads = 15290859
          sub_product = ExpaPerson.interested_sub_products[person.interested_sub_product] + 1 unless person.interested_sub_product.nil?
        elsif person.interested_program == 'global_talents'
          podio_app_decided_leads = 15291951
          sub_product = ExpaPerson.interested_sub_products[person.interested_sub_product] - 4 unless person.interested_sub_product.nil?
        end
        fields = {}
        fields['data-inscricao'] = {'start' => person.xp_created_at.strftime('%Y-%m-%d %H:%M:%S').to_s } unless person.xp_created_at.nil?
        fields['title'] = person.xp_full_name.to_s unless person.xp_full_name.nil?
        fields['expa-id'] = person.xp_id.to_i unless person.xp_id.nil?
        fields['email'] = [{'type' => 'home', 'value' => person.xp_email.to_s}] unless person.xp_email.nil?
        if !person.customized_fields.nil? && JSON.parse(person.customized_fields).key?('telefone')
          fields['telefone'] = [{'type' => 'home', 'value' => JSON.parse(person.customized_fields)['telefone']}]
        elsif !person.xp_phone.nil?
          fields['telefone'] = [{'type' => 'home', 'value' => person.xp_phone.to_s}]
        end
        fields['telefone'] = [{'type' => 'home', 'value' => person.xp_phone.to_s}] unless person.xp_phone.nil?
        fields['cl-marcado-no-expa-nao-conta-expansao-ainda'] = entities[person.xp_home_lc.xp_name] unless person.xp_home_lc.nil?
        fields['location-inscrito-escreve-isso-opcionalmente-no-expa'] = person.xp_location unless person.xp_location.blank?
        fields['sub-produto'] = sub_product unless person.interested_sub_product.nil?
        fields['entidade-mais-proxima'] = entities[person.entity_exchange_lc.xp_name] unless person.entity_exchange_lc.nil?
        fields['como-conheceu-a-aiesec'] = ExpaPerson.how_got_to_know_aiesecs[person.how_got_to_know_aiesec] + 1 unless person.how_got_to_know_aiesec.nil?
        fields['escolaridade'] = study_level.index(JSON.parse(person.control_podio)['escolaridade']['value'])
        if JSON.parse(person.control_podio).key?('universidade')
          fields['universidade'] = podio_helper_find_item_by_unique_id(universities[JSON.parse(person.control_podio)['universidade']['value']],'universidade').first['item_id']
        end
        if JSON.parse(person.control_podio).key?('curso')
          fields['curso'] = podio_helper_find_item_by_unique_id(courses[JSON.parse(person.control_podio)['curso']['value']],'curso').first['item_id']
        end

        puts fields
        Podio::Item.create(podio_app_decided_leads, {:fields => fields})

        item = self.podio_helper_find_item_by_expa_id(person.xp_id).first
        Podio::Item.delete(item['item_id']) unless item.nil?

        res = JSON.parse(person.control_podio)
        res['podio_status'] = 'podio_final'
        person.control_podio = res.to_json.to_s
        person.save
      end
    end

    people = ExpaPerson.where(xp_status: 0).order(xp_updated_at: :desc)
    people.each do |person|
      if person.control_podio.nil? || !JSON.parse(person.control_podio).key?('podio_status')
        podio_ogcdp_leads = 15290822
        fields = {}
        fields['data-inscricao'] = {'start' => person.xp_created_at.strftime('%Y-%m-%d %H:%M:%S').to_s } unless person.xp_created_at.nil?
        fields['title'] = person.xp_full_name.to_s unless person.xp_full_name.nil?
        fields['expa-id'] = person.xp_id.to_i unless person.xp_id.nil?
        fields['email'] = [{'type' => 'home', 'value' => person.xp_email.to_s}] unless person.xp_email.nil?
        fields['telefone'] = [{'type' => 'home', 'value' => person.xp_phone.to_s}] unless person.xp_phone.nil?
        fields['cl-marcado-no-expa-nao-conta-expansao-ainda'] = entities[person.xp_home_lc.xp_name] unless person.xp_home_lc.nil?
        fields['location-inscrito-escreve-isso-opcionalmente-no-expa'] = person.xp_location unless person.xp_location.blank?

        puts fields
        Podio::Item.create(podio_ogcdp_leads, {:fields => fields})
        if person.control_podio.nil?
          res = {}
        else
          res = JSON.parse(person.control_podio)
        end
        res['podio_status'] = 'podio_lead'
        person.control_podio = res.to_json.to_s
        person.save
      end

      if person.control_podio.nil? ||
          !JSON.parse(person.control_podio).key?('telefone_status') ||
          JSON.parse(person.control_podio).key?('telefone_status') == false

        item = podio_helper_find_item_by_expa_id(person.xp_id).first
        unless item.nil?
          fields = item['fields']
          location_index = telephone_index = fields.count

          for i in 0...fields.count
            telephone_index = i if fields[i]['external_id'] == 'telefone'
            location_index = i if fields[i]['external_id'] == 'location-inscrito-escreve-isso-opcionalmente-no-expa'
          end

          unless person.xp_phone.nil? || person.xp_location.blank?
            fields_to_update = {}
            if telephone_index == fields.count || fields[telephone_index]['values'][0]['value'] != person.xp_phone
              fields_to_update['telefone'] = [{'type' => 'home', 'value' => person.xp_phone.to_s}] unless person.xp_phone.nil?
            end
            if location_index == fields.count || fields[location_index]['values'][0]['value'] != person.xp_location
              fields_to_update['location-inscrito-escreve-isso-opcionalmente-no-expa'] = person.xp_location unless person.xp_location.blank?
            end

            unless fields_to_update.empty?
              Podio::Item.update(item['item_id'], {:fields => fields_to_update})

              if person.control_podio.nil?
                json = person.control_podio = {}
              else
                json = JSON.parse(person.control_podio)
              end

              json['telefone_status' => true]

              person.control_podio = json.to_json.to_s
              person.save
            end
          end
        end
      end
    end
  end

  def rd_from_podio_offline_lead
    Podio.setup(:api_key => ENV['PODIO_API_KEY'], :api_secret => ENV['PODIO_API_SECRET'])
    Podio.client.authenticate_with_credentials(ENV['PODIO_2_USERNAME'], ENV['PODIO_2_PASSWORD'])

    attributes = {:sort_by => 'last_edit_on'}
    app_id = 14573133 # App ORS oGCDP from Space Leads oGCDP
    attributes[:filters] = {118893658 => 1, 'created_on' =>{'from' => (Time.now - 1.day).strftime('%Y-%m-%d %H:%M:%S'), 'to' => (Time.now + 1.day).strftime('%Y-%m-%d %H:%M:%S')}}

    response = Podio.connection.post do |req|
      req.url "/item/app/#{app_id}/filter/"
      req.body = attributes
    end

    items = response.body['items']

    items.each do |item|
      mail_index = item['fields'].count
      for i in 0...item['fields'].count
        mail_index = i if item['fields'][i]['external_id'] == 'email'
      end
      unless mail_index == item['fields'].count
        begin
          Podio::Item.update(item['item_id'], {:fields => {'enviado-para-rd-station-bazicon' => 2}})
          person = ExpaPerson.new
          person.xp_email = item['fields'][mail_index]['values'][0]['value']
          send_to_rd(person, nil, self.rd_identifiers[:form_podio_offline], nil)
          person = nil
        rescue => exception
          puts exception.to_s
        end
      end
      puts item
    end
  end

  #TODO: Delete after migrate everything to Bazicon/EXPA and do not use Podio anymore
  def podio_helper_find_item_by_unique_id(unique_id, option)
    attributes = {:sort_by => 'last_edit_on'}
    if option == 'universidade'
      app_id = 14568134
      attributes[:filters] = {117992837 => unique_id}
    elsif option == 'curso'
      app_id = 14568143
      attributes[:filters] = {117992834 => unique_id}
    end

    response = Podio.connection.post do |req|
      req.url "/item/app/#{app_id}/filter/"
      req.body = attributes
    end

    Podio::Item.collection(response.body).first
  end

  #TODO: Delete after migrate everything to Bazicon/EXPA and do not use Podio anymore
  def podio_helper_find_item_by_expa_id(expa_id)
    attributes = {:sort_by => 'last_edit_on'}
    attributes[:filters] = {117786190 => {'from'=>expa_id,'to'=>expa_id}}

    response = Podio.connection.post do |req|
      req.url '/item/app/15290822/filter/'
      req.body = attributes
    end
    Podio::Item.collection(response.body).first
  end

  def update_db_peoples(xp_person)
    person = ExpaPerson.find_by_xp_id(xp_person.id)

    if person.nil? && !ExpaPerson.exists?(person)
      person = ExpaPerson.new
      person.update_from_expa(xp_person)
      person.save
    else
      if person.xp_status != xp_person.status.to_s.downcase.gsub(' ','_')
        person.update_from_expa(xp_person)
        person.save
        case person.xp_status
          when 'in_progress'then send_to_rd(person, nil, self.rd_identifiers[:in_progress], nil) #TODO mandar se é GCDP ou GIP
          when 'accepted' then send_to_rd(person, nil, self.rd_identifiers[:accepted], nil)
          when 'approved' then send_to_rd(person, nil, self.rd_identifiers[:approved], nil)
          else nil
        end
      end
    end

    setup_expa_api
    applications = EXPA::People.get_applications(person.xp_id)
    unless applications.blank?
      applications.each do |xp_application|
        update_db_applications(xp_application)
      end
    end
    send_to_rd(person, nil, self.rd_identifiers[:expa], nil) #TODO enviar tambem applications (somente quanto ta accepted, match, relized, complted)
    person
  end

  def update_db_applications(xp_application)
    application = ExpaApplication.find_by_xp_id(xp_application.id)

    if application.nil?
      application = ExpaApplication.new
    end

    application.update_from_expa(EXPA::Applications.get_attributes(xp_application.id))
    application.save
  end

  def send_to_rd(person, application, identifier, tag)
    #TODO: colocar todos os campos do peoples e applications aqui no RD
    #TODO: colocar breaks conferindo todos os campos
    json_to_rd = {}
    json_to_rd['token_rdstation'] = ENV['RD_STATION_TOKEN']
    json_to_rd['identificador'] = identifier
    json_to_rd['email'] = person.xp_email unless person.xp_email.nil?
    json_to_rd['nome'] = person.xp_full_name unless person.xp_full_name.nil?
    json_to_rd['expa_id'] = person.xp_id unless person.xp_id.nil?
    json_to_rd['data_de_nascimento'] = person.xp_birthday_date unless person.xp_birthday_date.nil?
    json_to_rd['entidade'] = person.xp_home_lc.xp_name unless person.xp_home_lc.nil?
    json_to_rd['pais'] = person.xp_home_mc.xp_name unless person.xp_home_mc.nil?
    json_to_rd['status'] = person.xp_status unless person.xp_status.nil?
    json_to_rd['entrevistado'] = person.xp_interviewed  unless person.xp_interviewed.nil?
    json_to_rd['telefone'] = person.xp_phone unless person.xp_phone.nil?
    json_to_rd['pagamento'] = person.xp_payment unless person.xp_payment.nil?
    json_to_rd['nps'] = person.xp_nps_score unless person.xp_nps_score.nil?
    json_to_rd['entidade_OGX'] = person.entity_exchange_lc.xp_name unless person.entity_exchange_lc.nil?
    json_to_rd['como_conheceu_AIESEC'] = person.how_got_to_know_aiesec unless person.how_got_to_know_aiesec.nil?
    json_to_rd['programa_interesse'] = person.interested_program unless person.interested_program.nil?
    json_to_rd['sub_produto_interesse'] = person.interested_sub_product unless person.interested_sub_product.nil?
    json_to_rd['tag'] = tag unless tag.nil?
    unless application.nil?
      json_to_rd.merge!{
      }
    end
    uri = URI(ENV['RD_STATION_URL'])
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = json_to_rd.to_json
    begin
      puts https.request(req)
    rescue => exception
      puts exception.to_s
    end
  end

  def setup_expa_api
    if EXPA.client.nil?
      xp = EXPA.setup()
      xp.auth(ENV['ROBOZINHO_EMAIL'],ENV['ROBOZINHO_PASSWORD'])
    end
  end
end