using System;

namespace Tooler.Stationery.Models
{
    public class AgeResult
    {
        public int Years { get; set; }
        public int Months { get; set; }
        public int Days { get; set; }
        public int TotalDays { get; set; }
        public int TotalWeeks { get; set; }
        public long TotalHours { get; set; }
        public int DaysToNextBirthday { get; set; }
        public DayOfWeek BornDayOfWeek { get; set; }
        public DayOfWeek NextBirthdayDayOfWeek { get; set; }
    }

    /// <summary>
    /// Age calculation engine with exact calendar breakdown.
    /// </summary>
    public class AgeCalculatorModel
    {
        public static AgeResult CalculateAge(DateTime dob, DateTime asOfDate)
        {
            if (dob > asOfDate) throw new ArgumentException("Date of birth cannot be in the future.");

            int years = asOfDate.Year - dob.Year;
            int months = asOfDate.Month - dob.Month;
            int days = asOfDate.Day - dob.Day;

            if (days < 0)
            {
                months--;
                DateTime prevMonth = new DateTime(asOfDate.Year, asOfDate.Month, 1).AddDays(-1);
                days += prevMonth.Day;
            }

            if (months < 0)
            {
                years--;
                months += 12;
            }

            TimeSpan diff = asOfDate - dob;
            int totalDays = (int)diff.TotalDays;
            int totalWeeks = totalDays / 7;
            long totalHours = (long)diff.TotalHours;

            DateTime nextBday = new DateTime(asOfDate.Year, dob.Month, dob.Day);
            if (nextBday < asOfDate)
            {
                nextBday = new DateTime(asOfDate.Year + 1, dob.Month, dob.Day);
            }
            int daysToNextBday = (int)(nextBday - asOfDate).TotalDays;

            return new AgeResult
            {
                Years = years,
                Months = months,
                Days = days,
                TotalDays = totalDays,
                TotalWeeks = totalWeeks,
                TotalHours = totalHours,
                DaysToNextBirthday = daysToNextBday,
                BornDayOfWeek = dob.DayOfWeek,
                NextBirthdayDayOfWeek = nextBday.DayOfWeek
            };
        }
    }
}
