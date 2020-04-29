 require([
     "jquery",
     "splunkjs/mvc",
     "splunkjs/mvc/utils",
     "splunkjs/mvc/simplexml/ready!"
  ], function($,mvc,utils){
  
     $(document).on("click", "#uploadPanel .type-btn", function() {
         var url = "http://3.93.201.167:8000/manager/speechmatics/adddata/selectsource?input_mode=0";
         console.log(url);
         utils.redirect(url, false, "_blank");
     });
 });
