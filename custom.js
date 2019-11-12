define([
        'base/js/namespace',
        'base/js/promises',
        'jquery'
     ], function(Jupyter, promises, $) {
         promises.app_initialized.then(function(appname) {
             $('#header-container').hide();
             $('#notification_trusted').hide();
             Jupyter._target = '_self';
             $('#save_notebook_as').hide();
             $('#rename_notebook').hide();
             $('#new_notebook').hide();
         });
     });
