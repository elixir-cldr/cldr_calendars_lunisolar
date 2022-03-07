require Cldr.Calendar

defmodule MyApp.Cldr do
  use Cldr,
    locales: ["fa", "ar", "ar-EG", "en", "de", "zh", "ja", "ko", "zh-Hant", "zh-Hant-HK"],
    default_locale: "en",
    providers: [Cldr.Calendar, Cldr.Number, Cldr.DateTime]
end