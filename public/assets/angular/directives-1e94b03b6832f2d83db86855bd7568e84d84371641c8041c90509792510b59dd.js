function pageTitle(i,e){return{link:function(t,n){var o=function(i,t){var o="INSPINIA | Responsive Admin Theme";t.data&&t.data.pageTitle&&(o="INSPINIA | "+t.data.pageTitle),e(function(){n.text(o)})};i.$on("$stateChangeStart",o)}}}function sideNavigation(i){return{restrict:"A",link:function(e,t){i(function(){t.metisMenu()})}}}function responsiveVideo(){return{restrict:"A",link:function(i,e){var t=e,n=e.children();n.attr("data-aspectRatio",n.height()/n.width()).removeAttr("height").removeAttr("width"),$(window).resize(function(){var i=t.width();n.width(i).height(i*n.attr("data-aspectRatio"))}).resize()}}}function iboxTools(i){return{restrict:"A",scope:!0,templateUrl:"views/common/ibox_tools.html",controller:["$scope","$element",function(e,t){e.showhide=function(){var e=t.closest("div.ibox"),n=t.find("i:first"),o=e.find("div.ibox-content");o.slideToggle(200),n.toggleClass("fa-chevron-up").toggleClass("fa-chevron-down"),e.toggleClass("").toggleClass("border-bottom"),i(function(){e.resize(),e.find("[id^=map-]").resize()},50)},e.closebox=function(){var i=t.closest("div.ibox");i.remove()}}]}}function iboxToolsFullScreen(i){return{restrict:"A",scope:!0,templateUrl:"views/common/ibox_tools_full_screen.html",controller:["$scope","$element",function(e,t){e.showhide=function(){var e=t.closest("div.ibox"),n=t.find("i:first"),o=e.find("div.ibox-content");o.slideToggle(200),n.toggleClass("fa-chevron-up").toggleClass("fa-chevron-down"),e.toggleClass("").toggleClass("border-bottom"),i(function(){e.resize(),e.find("[id^=map-]").resize()},50)},e.closebox=function(){var i=t.closest("div.ibox");i.remove()},e.fullscreen=function(){var i=t.closest("div.ibox"),e=t.find("i.fa-expand");$("body").toggleClass("fullscreen-ibox-mode"),e.toggleClass("fa-expand").toggleClass("fa-compress"),i.toggleClass("fullscreen"),setTimeout(function(){$(window).trigger("resize")},100)}}]}}function minimalizaSidebar(){return{restrict:"A",template:'<a class="navbar-minimalize minimalize-styl-2 btn btn-primary " href="" ng-click="minimalize()"><i class="fa fa-bars"></i></a>',controller:["$scope","$element",function(i){i.minimalize=function(){$("body").toggleClass("mini-navbar"),!$("body").hasClass("mini-navbar")||$("body").hasClass("body-small")?($("#side-menu").hide(),setTimeout(function(){$("#side-menu").fadeIn(400)},200)):$("body").hasClass("fixed-sidebar")?($("#side-menu").hide(),setTimeout(function(){$("#side-menu").fadeIn(400)},100)):$("#side-menu").removeAttr("style")}}]}}function closeOffCanvas(){return{restrict:"A",template:'<a class="close-canvas-menu" ng-click="closeOffCanvas()"><i class="fa fa-times"></i></a>',controller:["$scope","$element",function(i){i.closeOffCanvas=function(){$("body").toggleClass("mini-navbar")}}]}}function vectorMap(){return{restrict:"A",scope:{myMapData:"="},link:function(i,e){var t=(e.vectorMap({map:"world_mill_en",backgroundColor:"transparent",regionStyle:{initial:{fill:"#e4e4e4","fill-opacity":.9,stroke:"none","stroke-width":0,"stroke-opacity":0}},series:{regions:[{values:i.myMapData,scale:["#1ab394","#22d6b1"],normalizeFunction:"polynomial"}]}}),function(){e.remove()});i.$on("$destroy",function(){t()})}}}function sparkline(){return{restrict:"A",scope:{sparkData:"=",sparkOptions:"="},link:function(i,e){i.$watch(i.sparkData,function(){t()}),i.$watch(i.sparkOptions,function(){t()});var t=function(){$(e).sparkline(i.sparkData,i.sparkOptions)}}}}function icheck(i){return{restrict:"A",require:"ngModel",link:function(e,t,n,o){return i(function(){var i;return i=n.value,e.$watch(n.ngModel,function(){$(t).iCheck("update")}),$(t).iCheck({checkboxClass:"icheckbox_square-green",radioClass:"iradio_square-green"}).on("ifChanged",function(r){if("checkbox"===$(t).attr("type")&&n.ngModel&&e.$apply(function(){return o.$setViewValue(r.target.checked)}),"radio"===$(t).attr("type")&&n.ngModel)return e.$apply(function(){return o.$setViewValue(i)})})})}}}function ionRangeSlider(){return{restrict:"A",scope:{rangeOptions:"="},link:function(i,e){e.ionRangeSlider(i.rangeOptions)}}}function dropZone(){return{restrict:"C",link:function(i,e){var t={url:"http://localhost:8080/upload",maxFilesize:100,paramName:"uploadfile",maxThumbnailFilesize:10,parallelUploads:1,autoProcessQueue:!1},n={addedfile:function(e){i.file=e,null!=this.files[1]&&this.removeFile(this.files[0]),i.$apply(function(){i.fileAdded=!0})},success:function(){}};dropzone=new Dropzone(e[0],t),angular.forEach(n,function(i,e){dropzone.on(e,i)}),i.processDropzone=function(){dropzone.processQueue()},i.resetDropzone=function(){dropzone.removeAllFiles()}}}}function chatSlimScroll(i){return{restrict:"A",link:function(e,t){i(function(){t.slimscroll({height:"234px",railOpacity:.4})})}}}function customValid(){return{require:"ngModel",link:function(i,e,t,n){i.$watch(t.ngModel,function(){var e="Inspinia";i.extras==e?n.$setValidity("cvalid",!0):n.$setValidity("cvalid",!1)})}}}function fullScroll(i){return{restrict:"A",link:function(e,t){i(function(){t.slimscroll({height:"100%",railOpacity:.9})})}}}function slimScroll(i){return{restrict:"A",scope:{boxHeight:"@"},link:function(e,t){i(function(){t.slimscroll({height:e.boxHeight,railOpacity:.9})})}}}function clockPicker(){return{restrict:"A",link:function(i,e){e.clockpicker()}}}function landingScrollspy(){return{restrict:"A",link:function(i,e){e.scrollspy({target:".navbar-fixed-top",offset:80})}}}function fitHeight(){return{restrict:"A",link:function(i,e){e.css("height",$(window).height()+"px"),e.css("min-height",$(window).height()+"px")}}}function truncate(i){return{restrict:"A",scope:{truncateOptions:"="},link:function(e,t){i(function(){t.dotdotdot(e.truncateOptions)})}}}function touchSpin(){return{restrict:"A",scope:{spinOptions:"="},link:function(i,e){i.$watch(i.spinOptions,function(){t()});var t=function(){$(e).TouchSpin(i.spinOptions)}}}}function markdownEditor(){return{restrict:"A",require:"ngModel",link:function(i,e,t,n){$(e).markdown({savable:!1,onChange:function(i){n.$setViewValue(i.getContent())}})}}}pageTitle.$inject=["$rootScope","$timeout"],sideNavigation.$inject=["$timeout"],iboxTools.$inject=["$timeout"],minimalizaSidebar.$inject=["$timeout"],icheck.$inject=["$timeout"],chatSlimScroll.$inject=["$timeout"],fullScroll.$inject=["$timeout"],iboxToolsFullScreen.$inject=["$timeout"],slimScroll.$inject=["$timeout"],truncate.$inject=["$timeout"],angular.module("inspinia").directive("pageTitle",pageTitle).directive("sideNavigation",sideNavigation).directive("iboxTools",iboxTools).directive("minimalizaSidebar",minimalizaSidebar).directive("vectorMap",vectorMap).directive("sparkline",sparkline).directive("icheck",icheck).directive("ionRangeSlider",ionRangeSlider).directive("dropZone",dropZone).directive("responsiveVideo",responsiveVideo).directive("chatSlimScroll",chatSlimScroll).directive("customValid",customValid).directive("fullScroll",fullScroll).directive("closeOffCanvas",closeOffCanvas).directive("clockPicker",clockPicker).directive("landingScrollspy",landingScrollspy).directive("fitHeight",fitHeight).directive("iboxToolsFullScreen",iboxToolsFullScreen).directive("slimScroll",slimScroll).directive("truncate",truncate).directive("touchSpin",touchSpin).directive("markdownEditor",markdownEditor);