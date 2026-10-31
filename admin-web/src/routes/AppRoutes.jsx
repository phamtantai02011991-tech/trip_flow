import React from "react";
import DashboardPage from "../pages/dashboard/DashboardPage";
import ProvincesPage from "../pages/provinces/ProvincesPage";
import DestinationsPage from "../pages/destinations/DestinationsPage";
import LocalFoodsPage from "../pages/local-foods/LocalFoodsPage";
import RestaurantsPage from "../pages/restaurants/RestaurantsPage";
import SampleItinerariesPage from "../pages/itineraries/SampleItinerariesPage";
import UsersPage from "../pages/users/UsersPage";
import ReviewsReportsPage from "../pages/reports/ReviewsReportsPage";
import PartnersSponsorsPage from "../pages/partners/PartnersSponsorsPage";
import SystemSettingsPage from "../pages/settings/SystemSettingsPage";

export default function AppRoutes({
  activeTab,
  setActiveTab,
  snapshot,
  onRefresh,
  showToast,
}) {
  switch (activeTab) {
    case "dashboard":
      return (
        <DashboardPage
          snapshot={snapshot}
          setActiveTab={setActiveTab}
        />
      );
    case "provinces":
      return (
        <ProvincesPage
          provinces={snapshot.provinces}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "destinations":
      return (
        <DestinationsPage
          destinations={snapshot.destinations}
          provinces={snapshot.provinces}
          categories={snapshot.categories}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "local-foods":
      return (
        <LocalFoodsPage
          localFoods={snapshot.localFoods}
          provinces={snapshot.provinces}
          restaurants={snapshot.restaurants}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "restaurants":
      return (
        <RestaurantsPage
          restaurants={snapshot.restaurants}
          provinces={snapshot.provinces}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "itineraries":
      return (
        <SampleItinerariesPage
          itineraries={snapshot.itineraries}
          provinces={snapshot.provinces}
          destinations={snapshot.destinations}
          restaurants={snapshot.restaurants}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "users":
      return (
        <UsersPage
          users={snapshot.users}
          provinces={snapshot.provinces}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "reports":
      return (
        <ReviewsReportsPage
          reports={snapshot.reports}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "partners":
      return (
        <PartnersSponsorsPage
          destinations={snapshot.destinations}
          restaurants={snapshot.restaurants}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    case "settings":
      return (
        <SystemSettingsPage
          auditLogs={snapshot.auditLogs}
          roles={snapshot.roles}
          quota={snapshot.dashboard?.maps_api_quota}
          onRefresh={onRefresh}
          showToast={showToast}
        />
      );
    default:
      return (
        <DashboardPage
          snapshot={snapshot}
          setActiveTab={setActiveTab}
        />
      );
  }
}
