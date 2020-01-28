# On localization:

- Some of the content is only visible on admin side, this content is left as is in the Finnish locale files. 
- Translations or information is required for lines prefixed with Fi_fi_locale_ or Sv_sv_locale_ unless specified otherwise in the comments of the file
- Translation for locale already translated finnish should be checked
- Translations in Finnish in Swedish locale files should be changed
- Localization for privacy information and help information should be done directly to the views 
	- app/views/pages/privacy.fi-FI.html.erb
	- app/views/pages/help.fi-FI.html.erb
	- app/views/pages/privacy.sv-SV.html.erb
	- app/views/pages/help.sv-SV.html.erb

Parameters in the translations such as %{threshold} or %{quantity} get replaced by some value depending on the state of the software.
The parameter should be left as it is, and 
Some of the common parameters:
- %{href} - localized hyperlink to another website or another part of this site
- %{threshold} - number of signatures requires for an answer or debate
- %{quantity} or %{count} - a number
- %{date} - localized date
- %{creator} - creator's name oŕ other identification
- %{petition} - name of the petition

## Localizing Finnish 
Huom: Parametrejen mukana tulevaa tietoa ei pysty muokata, joka tuottaa hieman ongelmia suomen taivutusmuotojen kanssa.
Esimerkiksi "Support %{creator}’s petition" toimii hyvin, mutta suoraa suomennosta "Tue %{creator} aloitetta" ei saa taivutettua posessiiviseen muotoon.
Erillainen muoto kuten "Tue partiolaisen %{creator} aloitetta" taas toimii.
