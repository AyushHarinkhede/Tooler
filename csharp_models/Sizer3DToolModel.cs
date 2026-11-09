using System;
using Tooler.Stationery.Geometry3D;

namespace Tooler.Stationery.Models
{
    public struct InternationalRingSizes
    {
        public string US;
        public string UK;
        public string EU;
        public string Japan;
    }

    /// <summary>
    /// 3D Ring, Bangle and Screen Caliper geometry model.
    /// </summary>
    public class Sizer3DToolModel
    {
        public double RingDiameterMm { get; set; } = 18.2;
        public double BangleDiameterMm { get; set; } = 60.0;
        public double PixelsPerMm { get; set; } = 3.78;

        public double RingCircumferenceMm => RingDiameterMm * Math.PI;
        public double BangleCircumferenceCm => (BangleDiameterMm * Math.PI) / 10.0;

        public InternationalRingSizes GetRingSizeMapping()
        {
            if (RingDiameterMm < 14.5) return new InternationalRingSizes { US = "3", UK = "F", EU = "44", Japan = "4" };
            if (RingDiameterMm < 15.3) return new InternationalRingSizes { US = "4", UK = "H", EU = "47", Japan = "7" };
            if (RingDiameterMm < 16.1) return new InternationalRingSizes { US = "5", UK = "J 1/2", EU = "49", Japan = "9" };
            if (RingDiameterMm < 16.9) return new InternationalRingSizes { US = "6", UK = "M", EU = "52", Japan = "12" };
            if (RingDiameterMm < 17.7) return new InternationalRingSizes { US = "7", UK = "O", EU = "54", Japan = "14" };
            if (RingDiameterMm < 18.5) return new InternationalRingSizes { US = "8", UK = "Q", EU = "57", Japan = "16" };
            if (RingDiameterMm < 19.4) return new InternationalRingSizes { US = "9", UK = "S", EU = "59", Japan = "18" };
            if (RingDiameterMm < 20.2) return new InternationalRingSizes { US = "10", UK = "T 1/2", EU = "62", Japan = "20" };
            if (RingDiameterMm < 21.0) return new InternationalRingSizes { US = "11", UK = "V 1/2", EU = "65", Japan = "23" };
            return new InternationalRingSizes { US = "12+", UK = "Z+", EU = "67+", Japan = "25+" };
        }

        public Stationery3DMesh Generate3DRingTorusMesh(int segments = 24)
        {
            double rMajor = RingDiameterMm / 2.0;
            double rMinor = 1.2; // Band thickness

            var vertices = new Vector3D[segments * segments];
            int idx = 0;
            for (int i = 0; i < segments; i++)
            {
                double u = i * 2.0 * Math.PI / segments;
                for (int j = 0; j < segments; j++)
                {
                    double v = j * 2.0 * Math.PI / segments;
                    double x = (rMajor + rMinor * Math.Cos(v)) * Math.Cos(u);
                    double y = (rMajor + rMinor * Math.Cos(v)) * Math.Sin(u);
                    double z = rMinor * Math.Sin(v);
                    vertices[idx++] = new Vector3D(x, y, z);
                }
            }

            return new Stationery3DMesh("RingTorus", vertices, new int[0][], "#FFD700");
        }
    }
}
