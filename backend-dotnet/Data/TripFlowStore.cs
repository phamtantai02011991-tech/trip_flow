using TripFlow.Api.Models;

namespace TripFlow.Api.Data;

public interface ITripFlowStore
{
    List<Province> GetProvinces(string? region, string? query);
    Province? GetProvinceById(int id);

    List<Destination> GetDestinations(int? provinceId, string? category, string? query);
    Destination? GetDestinationById(int id);

    List<Restaurant> GetRestaurants(int? provinceId, string? query, double? minRating, bool? isHighRated);
    Restaurant? GetRestaurantById(int id);

    List<Hotel> GetHotels(int? provinceId, string? query);
    Hotel? GetHotelById(int id);

    List<LocalFood> GetLocalFoods(int? provinceId, string? query);
    LocalFood? GetLocalFoodById(int id);

    List<Itinerary> GetItineraries();
    Itinerary? GetItineraryById(int id);
    Itinerary AddItinerary(Itinerary itinerary);
}

public class TripFlowStore : ITripFlowStore
{
    private readonly List<Province> _provinces = TripFlowSeedData.GetProvinces();
    private readonly List<Destination> _destinations = TripFlowSeedData.GetDestinations();
    private readonly List<Restaurant> _restaurants = TripFlowSeedData.GetRestaurants();
    private readonly List<Hotel> _hotels = TripFlowSeedData.GetHotels();
    private readonly List<LocalFood> _localFoods = TripFlowSeedData.GetLocalFoods();
    private readonly List<Itinerary> _itineraries = TripFlowSeedData.GetItineraries();

    public List<Province> GetProvinces(string? region, string? query)
    {
        var result = _provinces.AsEnumerable();
        if (!string.IsNullOrWhiteSpace(region) && region != "Tất cả")
        {
            result = result.Where(p => p.Region.Equals(region, StringComparison.OrdinalIgnoreCase));
        }
        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLowerInvariant();
            result = result.Where(p => p.Name.ToLowerInvariant().Contains(q) || p.Description.ToLowerInvariant().Contains(q));
        }
        return result.ToList();
    }

    public Province? GetProvinceById(int id) => _provinces.FirstOrDefault(p => p.Id == id);

    public List<Destination> GetDestinations(int? provinceId, string? category, string? query)
    {
        var result = _destinations.AsEnumerable();
        if (provinceId.HasValue && provinceId.Value > 0)
        {
            result = result.Where(d => d.ProvinceId == provinceId.Value);
        }
        if (!string.IsNullOrWhiteSpace(category))
        {
            result = result.Where(d => d.Category.Contains(category, StringComparison.OrdinalIgnoreCase));
        }
        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLowerInvariant();
            result = result.Where(d => d.Name.ToLowerInvariant().Contains(q) || d.Description.ToLowerInvariant().Contains(q) || d.Address.ToLowerInvariant().Contains(q));
        }
        return result.ToList();
    }

    public Destination? GetDestinationById(int id) => _destinations.FirstOrDefault(d => d.Id == id);

    public List<Restaurant> GetRestaurants(int? provinceId, string? query, double? minRating, bool? isHighRated)
    {
        var result = _restaurants.AsEnumerable();
        if (provinceId.HasValue && provinceId.Value > 0)
        {
            result = result.Where(r => r.ProvinceId == provinceId.Value);
        }
        if (minRating.HasValue)
        {
            result = result.Where(r => r.Rating >= minRating.Value);
        }
        if (isHighRated.HasValue && isHighRated.Value)
        {
            result = result.Where(r => r.IsHighRated);
        }
        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLowerInvariant();
            result = result.Where(r => r.Name.ToLowerInvariant().Contains(q) || r.Specialties.ToLowerInvariant().Contains(q) || r.Address.ToLowerInvariant().Contains(q));
        }
        return result.ToList();
    }

    public Restaurant? GetRestaurantById(int id) => _restaurants.FirstOrDefault(r => r.Id == id);

    public List<Hotel> GetHotels(int? provinceId, string? query)
    {
        var result = _hotels.AsEnumerable();
        if (provinceId.HasValue && provinceId.Value > 0)
        {
            result = result.Where(h => h.ProvinceId == provinceId.Value);
        }
        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLowerInvariant();
            result = result.Where(h => h.Name.ToLowerInvariant().Contains(q) || h.Address.ToLowerInvariant().Contains(q));
        }
        return result.ToList();
    }

    public Hotel? GetHotelById(int id) => _hotels.FirstOrDefault(h => h.Id == id);

    public List<LocalFood> GetLocalFoods(int? provinceId, string? query)
    {
        var result = _localFoods.AsEnumerable();
        if (provinceId.HasValue && provinceId.Value > 0)
        {
            result = result.Where(f => f.ProvinceId == provinceId.Value);
        }
        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLowerInvariant();
            result = result.Where(f => f.Name.ToLowerInvariant().Contains(q) || f.Description.ToLowerInvariant().Contains(q));
        }
        return result.ToList();
    }

    public LocalFood? GetLocalFoodById(int id) => _localFoods.FirstOrDefault(f => f.Id == id);

    public List<Itinerary> GetItineraries() => _itineraries.ToList();

    public Itinerary? GetItineraryById(int id) => _itineraries.FirstOrDefault(i => i.Id == id);

    public Itinerary AddItinerary(Itinerary itinerary)
    {
        itinerary.Id = _itineraries.Count > 0 ? _itineraries.Max(i => i.Id) + 1 : 1;
        itinerary.CreatedAt = DateTime.UtcNow;
        _itineraries.Add(itinerary);
        return itinerary;
    }
}
