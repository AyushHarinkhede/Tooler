using System;
using Tooler.Stationery.Geometry3D;

namespace Tooler.Stationery.Models
{
    /// <summary>
    /// 3D Geometry Pencil Case model with hinged open/close perspective.
    /// </summary>
    public class Stationery3DBoxModel
    {
        public double WidthMm { get; set; } = 200.0;
        public double HeightMm { get; set; } = 80.0;
        public double DepthMm { get; set; } = 25.0;

        public double LidAngleRadians { get; private set; } = 0.0; // 0 = closed, ~1.8 = open
        public bool IsOpen => LidAngleRadians > 0.1;

        public void Open(double progress0To1)
        {
            double clamped = Math.Clamp(progress0To1, 0.0, 1.0);
            LidAngleRadians = clamped * (Math.PI / 2.2);
        }

        public void Close()
        {
            LidAngleRadians = 0.0;
        }

        public Stationery3DMesh GenerateBoxMesh()
        {
            double halfW = WidthMm / 2.0;
            double halfH = HeightMm / 2.0;
            double halfD = DepthMm / 2.0;

            var vertices = new Vector3D[]
            {
                new Vector3D(-halfW, -halfH, -halfD),
                new Vector3D(halfW, -halfH, -halfD),
                new Vector3D(halfW, halfH, -halfD),
                new Vector3D(-halfW, halfH, -halfD),
                new Vector3D(-halfW, -halfH, halfD),
                new Vector3D(halfW, -halfH, halfD),
                new Vector3D(halfW, halfH, halfD),
                new Vector3D(-halfW, halfH, halfD)
            };

            var faces = new int[][]
            {
                new int[] { 0, 1, 2, 3 }, // Front
                new int[] { 5, 4, 7, 6 }, // Back
                new int[] { 4, 0, 3, 7 }, // Left
                new int[] { 1, 5, 6, 2 }, // Right
                new int[] { 3, 2, 6, 7 }, // Top
                new int[] { 4, 5, 1, 0 }  // Bottom
            };

            return new Stationery3DMesh("GeometryBox", vertices, faces, "#1E3C72");
        }
    }
}
