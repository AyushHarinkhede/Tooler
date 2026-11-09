using System;
using System.Collections.Generic;

namespace Tooler.Stationery.Models
{
    public enum UnitCategory
    {
        Length,
        Weight,
        Temperature,
        Height,
        Area,
        Volume,
        Speed,
        DataStorage
    }

    /// <summary>
    /// Universal conversion matrix for all Tooler units.
    /// </summary>
    public class UniversalConverterModel
    {
        private static readonly Dictionary<string, double> LengthToMeters = new Dictionary<string, double>
        {
            ["Meters"] = 1.0,
            ["Kilometers"] = 1000.0,
            ["Centimeters"] = 0.01,
            ["Millimeters"] = 0.001,
            ["Miles"] = 1609.344,
            ["Yards"] = 0.9144,
            ["Feet"] = 0.3048,
            ["Inches"] = 0.0254
        };

        private static readonly Dictionary<string, double> WeightToKg = new Dictionary<string, double>
        {
            ["Kilograms"] = 1.0,
            ["Grams"] = 0.001,
            ["Milligrams"] = 0.000001,
            ["Pounds"] = 0.45359237,
            ["Ounces"] = 0.0283495,
            ["Tons"] = 1000.0
        };

        public static double ConvertLength(double value, string fromUnit, string toUnit)
        {
            double meters = value * LengthToMeters[fromUnit];
            return meters / LengthToMeters[toUnit];
        }

        public static double ConvertWeight(double value, string fromUnit, string toUnit)
        {
            double kg = value * WeightToKg[fromUnit];
            return kg / WeightToKg[toUnit];
        }

        public static double ConvertTemperature(double value, string fromUnit, string toUnit)
        {
            // Convert to Celsius
            double c = value;
            if (fromUnit == "Fahrenheit") c = (value - 32) * 5.0 / 9.0;
            else if (fromUnit == "Kelvin") c = value - 273.15;
            else if (fromUnit == "Rankine") c = (value - 491.67) * 5.0 / 9.0;
            else if (fromUnit == "Reaumur") c = value * 5.0 / 4.0;

            // Convert to Target
            if (toUnit == "Celsius") return c;
            if (toUnit == "Fahrenheit") return (c * 9.0 / 5.0) + 32;
            if (toUnit == "Kelvin") return c + 273.15;
            if (toUnit == "Rankine") return (c + 273.15) * 9.0 / 5.0;
            if (toUnit == "Reaumur") return c * 4.0 / 5.0;
            return c;
        }
    }
}
