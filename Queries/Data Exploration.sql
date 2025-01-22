--Selecting the data we're going to be using
SELECT 
	   [location]
      ,[date]
      ,[total_cases]
      ,[new_cases]
--    ,[new_cases_smoothed]
      ,[total_deaths]
	  ,[population]
/*    ,[new_deaths]
      ,[new_deaths_smoothed]
      ,[total_cases_per_million]
      ,[new_cases_per_million]
      ,[new_cases_smoothed_per_million]
      ,[total_deaths_per_million]
      ,[new_deaths_per_million]
      ,[new_deaths_smoothed_per_million]
      ,[reproduction_rate]
      ,[icu_patients]
      ,[icu_patients_per_million]
      ,[hosp_patients]
      ,[hosp_patients_per_million]
      ,[weekly_icu_admissions]
      ,[weekly_icu_admissions_per_million]
      ,[weekly_hosp_admissions]
      ,[weekly_hosp_admissions_per_million]*/
  FROM CovidDatabase.[dbo].[CovidDeathsCleaned]


-- Looking at Total Cases Vs Total Deaths
SELECT continent,location,MAX(CAST(total_cases AS bigint)) AS TOTAL_CASES, MAX(CAST(total_deaths AS bigint)) AS TOTAL_DEATHS,
ROUND(CAST(((MAX(CAST(total_deaths AS bigint)) * 1.0) /(MAX(CAST(total_cases AS bigint) * 1.0))) AS FLOAT) * 100,2) AS Death_Percenetage  FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
GROUP BY continent,location
ORDER BY Death_Percenetage DESC;

-- Looking at Total Cases Vs Population
-- Shows the percentage of the population the contracted the virus at any given point in time 
SELECT continent,location,MAX(CAST(total_cases AS bigint)) AS TOTAL_CASES, AVG(CAST(population AS bigint)) AS Population,
ROUND(CAST(((MAX(CAST(total_cases AS bigint)) * 1.0) /(AVG(CAST(population AS bigint) * 1.0))) AS FLOAT) * 100,2) AS InfectionRate FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
WHERE continent IS NOT NULL
GROUP BY continent,location
ORDER BY InfectionRate DESC;

-- Showing the continents with the highest death count
SELECT continent, MAX(CAST(total_deaths AS bigint)) AS TOTAL_DEATHS FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TOTAL_DEATHS DESC;

-- Global Numbers
SELECT date, SUM(new_cases) AS TOTAL_CASES,SUM(new_deaths) AS TOTAL_DEATHS,
ROUND(CAST((SUM(CAST(NULLIF(new_deaths,0) AS int)) * 1.0) / (SUM(CAST(NULLIF(new_cases,0) AS int)) * 1.0) AS FLOAT) * 100,2) AS Death_Percentage 
FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
GROUP BY date
ORDER BY Death_Percentage DESC;

-- Total Global Numbers
SELECT SUM(new_cases) AS TOTAL_CASES,SUM(new_deaths) AS TOTAL_DEATHS,
ROUND(CAST((SUM(CAST(NULLIF(new_deaths,0) AS int)) * 1.0) / (SUM(CAST(NULLIF(new_cases,0) AS int)) * 1.0) AS FLOAT) * 100,2) AS Death_Percentage 
FROM CovidDatabase.[dbo].[CovidDeathsCleaned]

-- % of People Fully Vaccinated in a Country
SELECT CD.location AS Country,AVG(CD.population) AS Population,MAX(CV.people_fully_vaccinated) AS People_Fully_Vaccinated, 
ROUND(CAST(((MAX(CAST(CV.people_fully_vaccinated AS bigint)) * 1.0) /(AVG(CAST(CD.population AS bigint) * 1.0))) AS FLOAT) * 100,2) AS Vaccination_Percentage
FROM CovidDatabase.dbo.CovidDeathsCleaned CD
JOIN CovidDatabase.dbo.CovidVaccincationsCleaned CV ON
CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
GROUP BY CD.location
ORDER BY Vaccination_Percentage DESC


-- Global Population
WITH Global_Population(Country,Population) AS
(SELECT location,AVG(population) FROM CovidDatabase.dbo.CovidDeathsCleaned
WHERE location IS NOT NULL
GROUP BY location),

-- % of People Fully Vaccianted Globally
Full_Vaccinated_Country(Country,People_Vaccinated) AS
(SELECT location,MAX(people_fully_vaccinated) FROM CovidDatabase.dbo.CovidVaccincationsCleaned
WHERE location IS NOT NULL
GROUP BY location)

SELECT (SELECT SUM(Population) FROM Global_Population) AS Population,SUM(People_Vaccinated) AS People_Vaccinated,
ROUND(CAST(((SUM(People_Vaccinated) * 1.0) /(SELECT SUM(Population) FROM Global_Population) * 1.0) AS FLOAT) * 100,2) AS Percentage_Vaccinated
 FROM Full_Vaccinated_Country

 -- Total Vaccinations in a Country
SELECT CD.location AS Country,CD.date AS date,CD.population AS Population,CV.new_vaccinations AS New_Vaccinations,
SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.date) AS Total_Vaccinations
FROM CovidDatabase.dbo.CovidDeathsCleaned CD
JOIN CovidDatabase.dbo.CovidVaccincationsCleaned CV ON
CD.location = CV.location AND CD.date = CV.date

-- A Table to Track the cases,deaths,tests,vaccinations,vaccination %
CREATE TABLE OverallInfo (
Country nvarchar(255),
Continet nvarchar(255),
Date datetime,
Population numeric,
Cases numeric,
Total_Cases numeric,
Deaths numeric,
Total_Deaths numeric,
Tests numeric,
Total_Tests numeric,
Vaccinations numeric,
Total_Vaccinations numeric,
Vaccination_Percentage float
)
INSERT INTO OverallInfo
SELECT 
CD.location,
CD.continent,
CD.date,
CD.population,
CD.new_cases,
SUM(CD.new_cases) OVER (PARTITION BY CD.location ORDER BY CD.date),
CD.new_deaths,
SUM(CD.new_deaths) OVER (PARTITION BY CD.location ORDER BY CD.date),
CV.new_tests,
SUM(CV.new_tests) OVER (PARTITION BY CD.location ORDER BY CD.date),
CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.date),
ROUND(CAST((SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.date) * 1.0) / (CD.population * 1.0)AS FLOAT) * 100,2)
FROM CovidDatabase.dbo.CovidDeathsCleaned CD
JOIN CovidDatabase.dbo.CovidVaccincationsCleaned CV ON
CD.location = CV.location AND CD.date = CV.date

SELECT * FROM OverallInfo


-- View that displays % of People Fully Vaccinated in a Country
CREATE VIEW FullyVaccinatedCountry AS 
(
SELECT CD.location AS Country,AVG(CD.population) AS Population,MAX(CV.people_fully_vaccinated) AS People_Fully_Vaccinated, 
ROUND(CAST(((MAX(CAST(CV.people_fully_vaccinated AS bigint)) * 1.0) /(AVG(CAST(CD.population AS bigint) * 1.0))) AS FLOAT) * 100,2) AS Vaccination_Percentage
FROM CovidDatabase.dbo.CovidDeathsCleaned CD
JOIN CovidDatabase.dbo.CovidVaccincationsCleaned CV ON
CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
GROUP BY CD.location
)

-- View that displays GlobalVaccinationPercentage
CREATE VIEW GlobalVaccinationPercentage AS
	-- Global Population
	WITH Global_Population(Country,Population) AS
	(SELECT location,AVG(population) FROM CovidDatabase.dbo.CovidDeathsCleaned
	WHERE location IS NOT NULL
	GROUP BY location),

	-- % of People Fully Vaccianted Globally
	Full_Vaccinated_Country(Country,People_Vaccinated) AS
	(SELECT location,MAX(people_fully_vaccinated) FROM CovidDatabase.dbo.CovidVaccincationsCleaned
	WHERE location IS NOT NULL
	GROUP BY location)

	SELECT (SELECT SUM(Population) FROM Global_Population) AS Population,SUM(People_Vaccinated) AS People_Vaccinated,
	ROUND(CAST(((SUM(People_Vaccinated) * 1.0) /(SELECT SUM(Population) FROM Global_Population) * 1.0) AS FLOAT) * 100,2) AS Percentage_Vaccinated
	FROM Full_Vaccinated_Country

CREATE VIEW DeathPercentage AS
(
SELECT continent,location,MAX(CAST(total_cases AS bigint)) AS TOTAL_CASES, MAX(CAST(total_deaths AS bigint)) AS TOTAL_DEATHS,
ROUND(CAST(((MAX(CAST(total_deaths AS bigint)) * 1.0) /(MAX(CAST(total_cases AS bigint) * 1.0))) AS FLOAT) * 100,2) AS Death_Percenetage  FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
GROUP BY continent,location
)

CREATE VIEW InfectionRate AS
(
SELECT continent,location,MAX(CAST(total_cases AS bigint)) AS TOTAL_CASES, AVG(CAST(population AS bigint)) AS Population,
ROUND(CAST(((MAX(CAST(total_cases AS bigint)) * 1.0) /(AVG(CAST(population AS bigint) * 1.0))) AS FLOAT) * 100,2) AS InfectionRate FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
WHERE continent IS NOT NULL
GROUP BY continent,location
)

CREATE VIEW GlobalNumbers AS
(
SELECT date, SUM(new_cases) AS TOTAL_CASES,SUM(new_deaths) AS TOTAL_DEATHS,
ROUND(CAST((SUM(CAST(NULLIF(new_deaths,0) AS int)) * 1.0) / (SUM(CAST(NULLIF(new_cases,0) AS int)) * 1.0) AS FLOAT) * 100,2) AS Death_Percentage 
FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
GROUP BY date
)

CREATE VIEW TotalGlobalNumbers AS
(
SELECT SUM(new_cases) AS TOTAL_CASES,SUM(new_deaths) AS TOTAL_DEATHS,
ROUND(CAST((SUM(CAST(NULLIF(new_deaths,0) AS int)) * 1.0) / (SUM(CAST(NULLIF(new_cases,0) AS int)) * 1.0) AS FLOAT) * 100,2) AS Death_Percentage 
FROM CovidDatabase.[dbo].[CovidDeathsCleaned]
)