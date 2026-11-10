using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Models.Entities;

namespace TripFlow.Api.Data;

public class TripFlowDbContext : DbContext
{
    public TripFlowDbContext(DbContextOptions<TripFlowDbContext> options) : base(options) { }

    public DbSet<Province> Provinces => Set<Province>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Destination> Destinations => Set<Destination>();
    public DbSet<DestinationImage> DestinationImages => Set<DestinationImage>();
    public DbSet<LocalFood> LocalFoods => Set<LocalFood>();
    public DbSet<Restaurant> Restaurants => Set<Restaurant>();
    public DbSet<RestStop> RestStops => Set<RestStop>();

    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RolePermissionLink> RolePermissionLinks => Set<RolePermissionLink>();
    public DbSet<AdminRole> AdminRoles => Set<AdminRole>();
    public DbSet<SMSOTPVerification> SMSOTPVerifications => Set<SMSOTPVerification>();

    public DbSet<Trip> Trips => Set<Trip>();
    public DbSet<TripDay> TripDays => Set<TripDay>();
    public DbSet<TripStop> TripStops => Set<TripStop>();
    public DbSet<Expense> Expenses => Set<Expense>();
    public DbSet<Itinerary> Itineraries => Set<Itinerary>();
    public DbSet<ItineraryStop> ItineraryStops => Set<ItineraryStop>();

    public DbSet<PlaceReview> PlaceReviews => Set<PlaceReview>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<ContentReport> ContentReports => Set<ContentReport>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<PlaceCache> PlaceCaches => Set<PlaceCache>();
    public DbSet<SearchHistory> SearchHistories => Set<SearchHistory>();
    public DbSet<CrawlJob> CrawlJobs => Set<CrawlJob>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // RolePermissionLink Composite Primary Key
        modelBuilder.Entity<RolePermissionLink>()
            .HasKey(rpl => new { rpl.RoleId, rpl.PermissionId });

        modelBuilder.Entity<RolePermissionLink>()
            .HasOne(rpl => rpl.Role)
            .WithMany(r => r.RolePermissions)
            .HasForeignKey(rpl => rpl.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<RolePermissionLink>()
            .HasOne(rpl => rpl.Permission)
            .WithMany(p => p.RolePermissions)
            .HasForeignKey(rpl => rpl.PermissionId)
            .OnDelete(DeleteBehavior.Cascade);

        // Composite Indexes for Bounding Box
        modelBuilder.Entity<Destination>()
            .HasIndex(d => new { d.Latitude, d.Longitude })
            .HasDatabaseName("ix_destinations_lat_lng");

        modelBuilder.Entity<Restaurant>()
            .HasIndex(r => new { r.Latitude, r.Longitude })
            .HasDatabaseName("ix_restaurants_lat_lng");

        modelBuilder.Entity<RestStop>()
            .HasIndex(rs => new { rs.Latitude, rs.Longitude })
            .HasDatabaseName("ix_rest_stops_lat_lng");

        // Relationships cascade settings
        modelBuilder.Entity<Destination>()
            .HasMany(d => d.Images)
            .WithOne(img => img.Destination)
            .HasForeignKey(img => img.DestinationId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Trip>()
            .HasMany(t => t.Days)
            .WithOne(d => d.Trip)
            .HasForeignKey(d => d.TripId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Trip>()
            .HasMany(t => t.Stops)
            .WithOne(s => s.Trip)
            .HasForeignKey(s => s.TripId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Trip>()
            .HasMany(t => t.Expenses)
            .WithOne(e => e.Trip)
            .HasForeignKey(e => e.TripId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Itinerary>()
            .HasMany(i => i.Stops)
            .WithOne(s => s.Itinerary)
            .HasForeignKey(s => s.ItineraryId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
