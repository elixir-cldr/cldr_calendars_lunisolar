# Lunisolar Calendars

This library implements the Chinese, Japanese and Korean lunisolar calendars.

From [wikipedia](https://en.wikipedia.org/wiki/Chinese_calendar):

The traditional Chinese calendar (officially known as the Agricultural Calendar [農曆; 农历; Nónglì; 'farming calendar'], Former Calendar [舊曆; 旧历; Jiùlì], Traditional Calendar [老曆; 老历; Lǎolì] or Yin Calendar [陰曆; 阴历; Yīnlì; 'yin calendar']), is a lunisolar calendar which reckons years, months and days according to astronomical phenomena. In China it is defined by the Chinese national standard GB/T 33661–2017, "Calculation and promulgation of the Chinese calendar", issued by the Standardisation Administration of China on May 12, 2017.

Although modern-day China uses the Gregorian calendar, the traditional Chinese calendar governs holidays—such as the Chinese New Year and Lantern Festival—in both China and in overseas Chinese communities. It also gives the traditional Chinese nomenclature of dates within a year, which people use for selecting auspicious days for weddings, funerals, moving, or starting a business.

The evening state-run news program Xinwen Lianbo in the P.R.C. continues to announce the month and date in both the Gregorian and the traditional lunisolar calendar.

## Usage

[ex_cldr_calendars_lunisolar](https://hex.pm/packages/ex_cldr_calenars_lunisolar) conforms to both the `Calendar` and `Cldr.Calendar` behaviours and therefore the functions in the `Date`, `DateTime`, `NaiveDateTime`, `Time` and `Calendar` functions are supported.

For Elixir version 1.10 and later `Sigil_D` supports user-defined calendars:
```
iex> ~D[1736-03-30 Cldr.Calendar.Coptic]
~D[1736-03-30 Cldr.Calendar.Coptic]
```

## Localization

`ex_cldr_calendars_lunisolar` depends on [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars) which supports calendar localization. For full date and time formatting see [ex_cldr_dates_times](https://hex.pm/packages/ex_cldr_dates_times).

Basic localization is executed by the `Cldr.Calendar.localize/3`. For example:

```elixir
iex> Cldr.Calendar.localize(date, :month, locale: "en")
"Hator"

iex> Cldr.Calendar.localize(date, :day_of_week, locale: "en")
"Tue"

iex> Cldr.Calendar.localize(date, :day_of_week, locale: "ar-EG")
"الثلاثاء"

iex> Cldr.Calendar.localize(date, :month, locale: "ar-EG")
"هاتور"
```

## Relationship to other libraries

This library is part of the [CLDR](https://cldr.unicode.org)-based libraries for Elixir including:

* [ex_cldr](https://hex.pm/packages/ex_cldr)
* [ex_cldr_numbers](https://hex.pm/packages/ex_cldr_numbers)
* [ex_cldr_dates_times](https://hex.pm/packages/ex_cldr_dates_times)
* [ex_cldr_units](https://hex.pm/packages/ex_cldr_units)
* [ex_cldr_lists](https://hex.pm/packages/ex_cldr_lists)
* [ex_cldr_messages](https://hex.pm/packages/ex_cldr_messages)
* [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars)
* [ex_cldr_currencies](https://hex.pm/packages/ex_cldr_currencies)

## Installation

The package can be installed by adding `cldr_calendars_coptic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cldr_calendars_chinesec, "~> 0.1.0"}
  ]
end
```
Documentation can be found at [https://hexdocs.pm/cldr_calendars_chinese](https://hexdocs.pm/cldr_calendars_chinese).

