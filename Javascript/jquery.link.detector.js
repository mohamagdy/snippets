/*
	This plugin is used to detect urls in a text field/area and submits the url to the server.
	It can be used to fetch the url metadata as Facebook does
*/
(function ($) {
  $.fn.extend({
    detector: function (givenOptions) {
      return this.each(function () {
        var $this = $(this);
        var options = $.extend({
          interval: 750,
          beforeSendCallback: '',
          successCallback: '',
          errorCallback: '',
          apiURL: $this.data('url'),
          saveUrlTo: '',
          spinClass: '.spinner'
        }, givenOptions);

        var interval;
        var sentUrls = [];

        $this.bind('keyup', check)
          .bind('focus blur', function (event) {
            if (event.type == 'blur') clearInterval(checker);
            if (event.type == 'focus' && !interval) checker = setInterval(check, options.interval);
          });

        // actual function to do the character counting and notification
        function check() {
          var url = detectedUrl($this.val());

          if (url && sentUrls.indexOf(url) == -1) {
            $(options.saveUrlTo).val(url); // Saving the url
            sentUrls.push(url); // Pushing the url to the sent urls

            $.ajax({
              url: options.apiURL,
              data: {
                url: url
              },
              beforeSend: function (jqXHR, settings) {
                if (options.beforeSendCallback != '')
                  options.beforeSendCallback();

                $(options.spinClass).spin({
                  radius: 5,
                  rotate: 0,
                  width: 2,
                  lines: 13
                });
              },
              success: function (data, textStatus, jqXHR) {
                if (options.successCallback != '')
                  options.successCallback(data);
              },
              error: function (jqXHR, textStatus, data) {
                if (options.errorCallback != '')
                  options.errorCallback(data);
              },
              complete: function (jqXHR, textStatus) {
                $(options.spinClass).html('');
              }
            });
          }
        };

        function detectedUrl(text) {
          var urls = text.match(/(https?:\/\/[^\s]+)/g);
          return (urls ? urls[0] : false);
        };

        function initialize() {
          var url = detectedUrl($this.val());
          if (url)
            sentUrls.push(url)
        };

        // run an initial check
        initialize();
      });
    }
  });
})(jQuery);


// Example usage

$('.js-BlabContent').detector({
  apiURL: $('.js-BlabContent').data('url'),
  beforeSendCallback: disableBlabPostTrigger,
  successCallback: showURLFetchMeta, // Embeding the url meta into the page
  saveUrlTo: '.js-BlabURL' // Save the url in the HTML DOM
});