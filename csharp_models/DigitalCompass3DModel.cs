using System;
using Tooler.Stationery.Geometry3D;

namespace Tooler.Stationery.Models
{
    /// <summary>
    /// Digital compass 3D orientation model and cardinal calculation.
    /// </summary>
    public class DigitalCompass3DModel
    {
        public double HeadingDegrees { get; set; } = 0.0;
        public double TiltPitchDegrees { get; set; } = 0.0;
        public double TiltRollDegrees { get; set; } = 0.0;

        public string GetCardinalDirection()
        {
            double h = (HeadingDegrees % 360.0 + 360.0) % 360.0;
            if (h >= 337.5 || h < 22.5) return "North";
            if (h >= 22.5 && h < 67.5) return "Northeast";
            if (h >= 67.5 && h < 112.5) return "East";
            if (h >= 112.5 && h < 157.5) return "Southeast";
            if (h >= 157.5 && h < 202.5) return "South";
            if (h >= 202.5 && h < 247.5) return "Southwest";
            if (h >= 247.5 && h < 292.5) return "West";
            return "Northwest";
        }

        public Vector3D GetNeedleVector()
        {
            double rad = HeadingDegrees * Math.PI / 180.0;
            return new Vector3D(Math.Sin(rad), -Math.Cos(rad), 0);
        }
    }
}
