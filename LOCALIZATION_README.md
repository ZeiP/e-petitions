#On localization:

-Some of the content is only visible on admin side, this content is left as is in the Finnish locale files. 
-Translations or information is required for lines prefixed with Fi_fi_locale_ or Sv_sv_locale_ unless specified otherwise specified in the comments of the file
-Translation for locale already translated finnish should be checked
-Translations in Finnish in Swedish locale files should be changed
-Localization for privacy information and help information should be done directly to the views 
	app/views/pages/privacy.fi-FI.html.erb
	app/views/pages/help.fi-FI.html.erb
	app/views/pages/privacy.sv-SV.html.erb
	app/views/pages/help.sv-SV.html.erb