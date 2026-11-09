using System;
using System.Collections.Generic;

namespace Tooler.Stationery.Models
{
    public class CalcHistoryEntry
    {
        public string Expression { get; set; }
        public string Result { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        public CalcHistoryEntry(string expression, string result)
        {
            Expression = expression;
            Result = result;
        }
    }

    /// <summary>
    /// C# Calculator Engine replicating Tooler math algorithms and paper tape history.
    /// </summary>
    public class Calculator3DModel
    {
        public string CurrentExpression { get; private set; } = "0";
        public List<CalcHistoryEntry> History { get; } = new List<CalcHistoryEntry>();
        public bool IsScientificMode { get; set; } = false;

        public void AppendKey(string key)
        {
            if (CurrentExpression == "0" || CurrentExpression == "Error")
            {
                CurrentExpression = key;
            }
            else
            {
                CurrentExpression += key;
            }
        }

        public void Backspace()
        {
            if (CurrentExpression.Length > 1)
            {
                CurrentExpression = CurrentExpression.Substring(0, CurrentExpression.Length - 1);
            }
            else
            {
                CurrentExpression = "0";
            }
        }

        public void Clear()
        {
            CurrentExpression = "0";
        }

        public double CalculateFactorial(int n)
        {
            if (n < 0) return 0;
            double res = 1;
            for (int i = 2; i <= n; i++) res *= i;
            return res;
        }

        public double EvaluateScientificFunction(string func, double arg)
        {
            switch (func.ToLowerInvariant())
            {
                case "sin": return Math.Sin(arg * Math.PI / 180.0);
                case "cos": return Math.Cos(arg * Math.PI / 180.0);
                case "tan": return Math.Tan(arg * Math.PI / 180.0);
                case "sqrt": return Math.Sqrt(arg);
                case "log": return Math.Log10(arg);
                case "ln": return Math.Log(arg);
                case "abs": return Math.Abs(arg);
                default: throw new ArgumentException($"Unknown function {func}");
            }
        }

        public void CommitResult(string result)
        {
            History.Insert(0, new CalcHistoryEntry(CurrentExpression, result));
            CurrentExpression = result;
        }
    }
}
