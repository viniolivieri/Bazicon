class SendToExpa
  def self.call(params)
    new(params).call
  end

  attr_reader :params, :status

  def initialize(params)
    @params = params
    @status = true
  end

  def call
    @status = send_data_to_expa(params)
  end

  private

  def send_data_to_expa(params)
    url = 'https://opportunities.aiesec.org/auth'

    agent = Mechanize.new {|a| a.ssl_version, a.verify_mode = 'TLSv1',OpenSSL::SSL::VERIFY_NONE}
    page = agent.get(url)

    auth_form = page.forms[1]
    auth_form.field_with(:name => 'user[email]').value = email
    auth_form.field_with(:name => 'user[first_name]').value = name
    auth_form.field_with(:name => 'user[last_name]').value = lastname
    auth_form.field_with(:name => 'user[password]').value = password
    auth_form.field_with(:name => 'user[country]').value = 'Brazil'
    auth_form.field_with(:name => 'user[mc]').value = '1606'
    case interested_program
      when 'GCDP', 'GV'
        auth_form.field_with(:name => 'user[lc]').value = DigitalTransformation.hash_entities_podio_expa[DigitalTransformation.entities_ogcdp[lc.to_i]]['ids'][0]
        auth_form.field_with(:name => 'user[lc_input]').value = DigitalTransformation.entities_ogcdp[lc.to_i]
      when 'GIP', 'GT', 'GE'
        auth_form.field_with(:name => 'user[lc]').value = DigitalTransformation.hash_entities_podio_expa[DigitalTransformation.entities_ogip[lc.to_i]]['ids'][0]
        auth_form.field_with(:name => 'user[lc_input]').value = DigitalTransformation.entities_ogip[lc.to_i]
      else
        auth_form.field_with(:name => 'user[lc]').value = DigitalTransformation.hash_entities_podio_expa[DigitalTransformation.entities_ogcdp[lc.to_i]]['ids'][0]
        auth_form.field_with(:name => 'user[lc_input]').value = DigitalTransformation.entities_ogcdp[lc.to_i]
    end

    page = agent.submit(auth_form, auth_form.buttons.first)

    page.code.to_i == 200
  end
end