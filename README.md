# Lunisolar Calendars

This library implements the Chinese, Japanese and Korean lunisolar calendars. Lunisolar calendars use the lunar cycle to define months but the solar cycle to define years. In reconciling these two cycles, occasionally one of the lunar months is extended to bring the cycles into alignment. Since the number of months in a year does not change (its always 12), the extended month is called a "leap month".

The traditional Chinese, Japanese and Korean calendars all use the same astronomical principles with the only difference being the reference point from which the observations are made. Today, the Chinese calendar uses Beijing as the reference, the Japanese calendar uses Tokyo and the Korean calendar uses Seoul.

## Usage

[ex_cldr_calendars_lunisolar](https://hex.pm/packages/ex_cldr_calenars_lunisolar) conforms to both the `Calendar` and `Cldr.Calendar` behaviours and therefore the functions in the `Date`, `DateTime`, `NaiveDateTime`, `Time` and `Calendar` functions are supported.

For Elixir version 1.10 and later `Sigil_D` supports user-defined calendars:
```
iex> ~D[1736-03-30 Cldr.Calendar.Chinese]
~D[1736-03-30 Cldr.Calendar.Chinese]
```

## Lunisolar Date representation

Lunisolar calendars have a leap year when the lunar cycle falls too far out of alignment with the solar year. In those years, like Gregorian 2023, a leap month is inserted into the calendar. In 2023, the leap month is month 2 so the sequence of months goes "month 1" -> "month 2" -> "leap month 2" -> "month 3". The Elixir date structures can't accomodate this kind of annotation so the lunisolar calendar implementations in the library adopt a different approach. The month in the date struct is an *ordinal* month (ie considered the nth month) not the *cardinal* month as in other calendars.

This means that the month numbers in a lunisolar leap year are:

  | Calendar month | Date struct month | Example for Gregorian 2023 (Korean calendar 4356) using Date.to_string/2
  | :------------: | :---------------: | :------------------------------------------------------------------------
  | 1              | 1                 | "4356. 1. 1."
  | 2              | 2                 | "4356. 2. 1."
  | leap 2         | 3                 | "4356. 윤2. 1."
  | 3              | 4                 | "4356. 3. 1."
  | 4              | 5                 | "4356. 4. 1."


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

The package can be installed by adding `cldr_calendars_lunisolar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cldr_calendars_lunisolar, "~> 1.0"}
  ]
end
```
Documentation can be found at [https://hexdocs.pm/cldr_calendars_lunisolar](https://hexdocs.pm/cldr_calendars_lunisolar).

