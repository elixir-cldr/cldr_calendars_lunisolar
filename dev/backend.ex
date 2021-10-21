require Cldr.Calendar

defmodule MyApp.Cldr do
  use Cldr,
    locales: ["fa", "ar", "ar-EG", "en", "de", "zh", "ja", "ko"],
    default_locale: "en",
    providers: [Cldr.Calendar, Cldr.Number, Cldr.DateTime]
end