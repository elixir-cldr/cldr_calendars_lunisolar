# Lunisolar Calendars

This library implements the Chinese, Japanese and Korean lunisolar calendars. Lunisolar calendars use the lunar cycle to define months but the solar cycle to define years. In reconciling these two cycles, occasionally one of the lunar months is extended to bring the cycles into alignment. Since the number of months in a year does not change (they are always numbered 1 to 12), the extended month is called a "leap month".

The traditional Chinese, Japanese and Korean calendars all use the same astronomical principles with the only difference being the reference point from which the observations are made and the preferred epoch date. Today, the Chinese calendar uses Beijing as the reference, the Japanese calendar uses Tokyo and the Korean calendar uses Seoul.

## Usage

[ex_cldr_calendars_lunisolar](https://hex.pm/packages/ex_cldr_calenars_lunisolar) conforms to both the `Calendar` and `Cldr.Calendar` behaviours and therefore the functions in the `Date`, `DateTime`, `NaiveDateTime`, `Time` and `Calendar` functions are supported.

For Elixir version 1.10 and later `Sigil_D` supports user-defined calendars:
```elixir
iex> ~D[4660-03-30 Cldr.Calendar.Chinese]
~D[4660-03-30 Cldr.Calendar.Chinese]
```

## Lunisolar Date representation

Lunisolar calendars have a leap year when the lunar cycle falls too far out of alignment with the solar year. In those years, like Gregorian 2023, a leap month is inserted into the calendar. In 2023, the leap month is month 2 so the sequence of months goes "month 1" -> "month 2" -> "leap month 2" -> "month 3". The Elixir date structures can't accomodate this kind of annotation so the lunisolar calendar implementations in the library adopt a different approach. The month in the date struct is an *ordinal* month (ie considered the nth month) not the *cardinal* month as in other calendars. To create dates using the traditional lunisolar month notation see the next section.

This means that the month numbers in a lunisolar leap year are:

| Calendar month | Date struct month | Example for Gregorian 2023 (Korean calendar 4356) using Date.to_string/2 in :ko locale |
| :------------: | :---------------: | :------------------------------------------------------------------------------------- |
| 1              | 1                 | "4356. 1. 1."                                                                          |
| 2              | 2                 | "4356. 2. 1."                                                                          |
| leap 2         | 3                 | "4356. 윤2. 1."                                                                        |
| 3              | 4                 | "4356. 3. 1."                                                                          |
| 4              | 5                 | "4356. 4. 1."                                                                          |

## Dates with lunar months

Key events in China, Japan, Korea and other territories are defined by their lunar dates. Lunar new year is `01-01` (month-year), Buddha's birthday is celebrated on `04-08` and the Korean thanksgiving day is `08-15`. Note that these month numbers *do not* map directly to the date struct's ordinal month numbers. To facilitate creating dates in the traditional notation, the functions `Cldr.Calendar.Chinese.new/3`, `Cldr.Calendar.LunarJapanese.new/3` and `Cldr.Calendar.Korean.new/3` are provided. The notation `{lunar_month, :leap}` is used to denote the leap month in a leap year.

```elixir
# New Years day
iex> Cldr.Calendar.Chinese.new(4660, 1, 1)
{:ok, ~D[4660-01-01 Cldr.Calendar.Chinese]}

#Buddha's birthday
iex> Cldr.Calendar.LunarJapanese.new(1379, 4, 8)
{:ok, ~D[1379-05-08 Cldr.Calendar.LunarJapanese]}

# Korean thanksgiving day
iex> Cldr.Calendar.Korean.new(4356, 8, 15)
{:ok, ~D[4356-09-15 Cldr.Calendar.Korean]}

# A day in the leap month
iex> Cldr.Calendar.Chinese.new(4660, {3, :leap}, 1)
{:ok, ~D[4660-04-01 Cldr.Calendar.Chinese]}
iex> Cldr.Calendar.Chinese.new(4660, {4, :leap}, 1)
{:error, :invalid_date}
```

## Localization

`ex_cldr_calendars_lunisolar` depends on [ex_cldr_calendars](https://hex.pm/packages/ex_cldr_calendars) which supports calendar localization. For full date and time formatting see [ex_cldr_dates_times](https://hex.pm/packages/ex_cldr_dates_times).

Basic localization is executed by the `Cldr.Calendar.localize/3`. For example:

```elixir
# Months are ordinal numbers so in Gregorian 2023, Korean 4356
# the ordinal month 3 is the Korean leap month 2
iex> Cldr.Calendar.localize(~D[4356-03-01 Cldr.Calendar.Korean], :month, locale: :ko)
"윤2월"

# Since there is a leap month prior to ordinal month 4
# the month number localizes to 3
iex> Cldr.Calendar.localize(~D[4356-04-01 Cldr.Calendar.Korean], :month, locale: :ko)
"3월"

iex> Cldr.Calendar.localize(~D[4660-04-01 Cldr.Calendar.Chinese], :day_of_week)
"Thu"

iex> Cldr.Calendar.localize(~D[4660-04-01 Cldr.Calendar.Chinese], :day_of_week, locale: :zh)
"周四"
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

The package can be installed by adding `cldr_calendars_lunisolar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cldr_calendars_lunisolar, "~> 1.0"}
  ]
end
```
Documentation can be found at [https://hexdocs.pm/cldr_calendars_lunisolar](https://hexdocs.pm/cldr_calendars_lunisolar).

