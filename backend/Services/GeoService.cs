namespace TripFlow.Api.Services;

public record PointD(double Lat, double Lng);

public record ProjectionResult(
    double DistanceToRouteKm,
    double DetourDistanceKm,
    int EstimatedDetourMins,
    double RouteProgressPct
);

public interface IGeoService
{
    double DistanceKm(double lat1, double lng1, double lat2, double lng2);
    (double minLat, double maxLat, double minLng, double maxLng) BoundingBox(IEnumerable<PointD> points, double radiusKm);
    ProjectionResult ProjectPointToRoute(double pLat, double pLng, IReadOnlyList<PointD> routePoints);
    double CalculateSfcsScore(double rating, int reviewCount, bool isHighRated, double distanceToRouteKm);
}

public class GeoService : IGeoService
{
    public double DistanceKm(double lat1, double lng1, double lat2, double lng2)
    {
        double dLat = (lat2 - lat1) * Math.PI / 180.0;
        double dLng = (lng2 - lng1) * Math.PI / 180.0;
        double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                   Math.Cos(lat1 * Math.PI / 180.0) * Math.Cos(lat2 * Math.PI / 180.0) *
                   Math.Sin(dLng / 2) * Math.Sin(dLng / 2);
        double c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return 6371.0 * c;
    }

    public (double minLat, double maxLat, double minLng, double maxLng) BoundingBox(IEnumerable<PointD> points, double radiusKm)
    {
        var pts = points.ToList();
        if (pts.Count == 0) return (0, 0, 0, 0);

        double minLat = pts.Min(p => p.Lat);
        double maxLat = pts.Max(p => p.Lat);
        double minLng = pts.Min(p => p.Lng);
        double maxLng = pts.Max(p => p.Lng);

        double midLat = (minLat + maxLat) / 2.0;
        double deltaLat = radiusKm / 111.32;
        double deltaLng = radiusKm / (111.32 * Math.Cos(midLat * Math.PI / 180.0));

        return (minLat - deltaLat, maxLat + deltaLat, minLng - deltaLng, maxLng + deltaLng);
    }

    public ProjectionResult ProjectPointToRoute(double pLat, double pLng, IReadOnlyList<PointD> routePoints)
    {
        if (routePoints == null || routePoints.Count == 0)
        {
            return new ProjectionResult(999, 999, 99, 0);
        }

        if (routePoints.Count == 1)
        {
            double d = DistanceKm(pLat, pLng, routePoints[0].Lat, routePoints[0].Lng);
            return new ProjectionResult(d, d * 2, Math.Max(2, (int)(d * 5) + 1), 0);
        }

        double refLat = routePoints[0].Lat;
        double refLng = routePoints[0].Lng;
        double cosRef = Math.Cos(refLat * Math.PI / 180.0);

        // Chuyển sang toạ độ Cartesian phẳng km
        var cartPoints = routePoints.Select(p => new
        {
            X = (p.Lng - refLng) * 111.32 * cosRef,
            Y = (p.Lat - refLat) * 111.32
        }).ToList();

        double px = (pLng - refLng) * 111.32 * cosRef;
        double py = (pLat - refLat) * 111.32;

        double totalLength = 0;
        var segLengths = new double[cartPoints.Count - 1];
        for (int i = 0; i < cartPoints.Count - 1; i++)
        {
            double dx = cartPoints[i + 1].X - cartPoints[i].X;
            double dy = cartPoints[i + 1].Y - cartPoints[i].Y;
            segLengths[i] = Math.Sqrt(dx * dx + dy * dy);
            totalLength += segLengths[i];
        }

        if (totalLength < 0.001) totalLength = 0.001;

        double minDistance = double.MaxValue;
        double progressAtMin = 0;
        double currentLength = 0;

        for (int i = 0; i < cartPoints.Count - 1; i++)
        {
            double ax = cartPoints[i].X;
            double ay = cartPoints[i].Y;
            double bx = cartPoints[i + 1].X;
            double by = cartPoints[i + 1].Y;

            double vx = bx - ax;
            double vy = by - ay;
            double vLen2 = vx * vx + vy * vy;

            double t = 0;
            if (vLen2 > 0.00001)
            {
                t = ((px - ax) * vx + (py - ay) * vy) / vLen2;
                t = Math.Clamp(t, 0.0, 1.0);
            }

            double qx = ax + t * vx;
            double qy = ay + t * vy;

            double dist = Math.Sqrt((px - qx) * (px - qx) + (py - qy) * (py - qy));
            if (dist < minDistance)
            {
                minDistance = dist;
                progressAtMin = (currentLength + t * segLengths[i]) / totalLength * 100.0;
            }

            currentLength += segLengths[i];
        }

        double roundedDist = Math.Round(minDistance, 2);
        double detourKm = Math.Round(roundedDist * 2, 2);
        int estMins = Math.Max(2, (int)Math.Round(detourKm / 0.4) + 1);

        return new ProjectionResult(
            roundedDist,
            detourKm,
            estMins,
            Math.Round(Math.Clamp(progressAtMin, 0, 100), 1)
        );
    }

    public double CalculateSfcsScore(double rating, int reviewCount, bool isHighRated, double distanceToRouteKm)
    {
        // 1. Rating (max 60 điểm)
        double scoreRating = Math.Clamp(rating, 0, 5) * 12.0;

        // 2. Reviews Popularity (max 15 điểm)
        double scoreReviews = Math.Min(15.0, Math.Log10(Math.Max(1, reviewCount)) * 5.0);

        // 3. Proximity bonus (max 20 điểm)
        double scoreProximity = Math.Max(0.0, 20.0 - (distanceToRouteKm * 8.0));

        // 4. Quality Badge (max 10 điểm)
        double scoreBadge = isHighRated ? 10.0 : 0.0;

        return Math.Round(scoreRating + scoreReviews + scoreProximity + scoreBadge, 1);
    }
}
