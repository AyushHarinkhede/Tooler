using System;

namespace Tooler.Stationery.Geometry3D
{
    /// <summary>
    /// Represents a 3D coordinate in stationery space.
    /// </summary>
    public struct Vector3D
    {
        public double X { get; set; }
        public double Y { get; set; }
        public double Z { get; set; }

        public Vector3D(double x, double y, double z)
        {
            X = x;
            Y = y;
            Z = z;
        }

        public static Vector3D Zero => new Vector3D(0, 0, 0);

        public Vector3D RotateX(double angleRadians)
        {
            double cos = Math.Cos(angleRadians);
            double sin = Math.Sin(angleRadians);
            return new Vector3D(X, Y * cos - Z * sin, Y * sin + Z * cos);
        }

        public Vector3D RotateY(double angleRadians)
        {
            double cos = Math.Cos(angleRadians);
            double sin = Math.Sin(angleRadians);
            return new Vector3D(X * cos + Z * sin, Y, -X * sin + Z * cos);
        }

        public Vector3D RotateZ(double angleRadians)
        {
            double cos = Math.Cos(angleRadians);
            double sin = Math.Sin(angleRadians);
            return new Vector3D(X * cos - Y * sin, X * sin + Y * cos, Z);
        }

        public Point2D ProjectTo2D(double focalLength, double screenCenterX, double screenCenterY)
        {
            double distance = Z + focalLength;
            if (distance <= 0.001) distance = 0.001;
            double factor = focalLength / distance;
            return new Point2D(screenCenterX + (X * factor), screenCenterY + (Y * factor));
        }
    }

    /// <summary>
    /// Represents a 2D projection point on notebook paper.
    /// </summary>
    public struct Point2D
    {
        public double X { get; set; }
        public double Y { get; set; }

        public Point2D(double x, double y)
        {
            X = x;
            Y = y;
        }
    }

    /// <summary>
    /// 3D Mesh representation of a physical school stationery item.
    /// </summary>
    public class Stationery3DMesh
    {
        public string Name { get; set; }
        public Vector3D[] Vertices { get; set; }
        public int[][] Faces { get; set; }
        public string MaterialHexColor { get; set; }

        public Stationery3DMesh(string name, Vector3D[] vertices, int[][] faces, string hexColor)
        {
            Name = name;
            Vertices = vertices;
            Faces = faces;
            MaterialHexColor = hexColor;
        }
    }
}
