-- Create Database
CREATE DATABASE Portfolio_Project;

-- Select all data from CovidDeaths table
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;

-- Select specific columns from CovidDeaths
SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY Location, Date;

-- Calculate Death Percentage for the US
SELECT Location, Date, Total_Cases, Total_Deaths, 
       (Total_Deaths * 100.0 / NULLIF(Total_Cases, 0)) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY Location, Date;

-- Calculate Percentage of Population Infected
SELECT Location, Date, Population, Total_Cases,  
       (Total_Cases * 100.0 / NULLIF(Population, 0)) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY Location, Date;

-- Highest Infection Rate per Location
SELECT Location, Population, 
       MAX(Total_Cases) AS HighestInfectionCount,  
       MAX(Total_Cases * 100.0 / NULLIF(Population, 0)) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Total Death Count per Location
SELECT Location, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Total Death Count per Continent
SELECT Continent, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Continent
ORDER BY TotalDeathCount DESC;

-- Global Death Percentage
SELECT SUM(New_Cases) AS Total_Cases, 
       SUM(CAST(New_Deaths AS INT)) AS Total_Deaths, 
       (SUM(CAST(New_Deaths AS INT)) * 100.0 / NULLIF(SUM(New_Cases), 0)) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY Total_Cases, Total_Deaths;

-- Rolling People Vaccinated
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
       SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.Location = vac.Location AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL 
ORDER BY dea.Location, dea.Date;

-- Using CTE for Rolling People Vaccinated
WITH PopvsVac AS (
    SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
           SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.Location = vac.Location AND dea.Date = vac.Date
    WHERE dea.Continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated * 100.0 / NULLIF(Population, 0)) AS PercentPopulationVaccinated
FROM PopvsVac;

-- Create and Populate Table for PercentPopulationVaccinated
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
       SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.Location = vac.Location AND dea.Date = vac.Date;

-- Select data from PercentPopulationVaccinated
SELECT *, (RollingPeopleVaccinated * 100.0 / NULLIF(Population, 0)) AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

-- Create a View for PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
       SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.Location = vac.Location AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;
