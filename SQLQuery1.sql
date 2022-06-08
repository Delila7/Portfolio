Select *
From PortfolioProject..CovidDeaths
Order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--Order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order By 1,2 --First order by Location, then by date

--Look at Total Cases vs Total Deaths
--What is the percentage of people who died (who had Covid) per country? (likelihood of dying given covid infection)
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where Location like '%states%'
Order By 1,2

--Total Cases vs. Population
--What percentage of the population has gotten Covid?
Select Location, date, population, total_cases, (total_cases/population)*100 as CovidPercent
From PortfolioProject..CovidDeaths
Where Location like '%states%'
Order By 1,2

--Countries with Highest Infection Rate compared to population
--What countries have the highest infection rates compared to the population
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
Order By PercentPopulationInfected desc

--Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount --cast max deaths as integer to fix issue with variable type
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location
Order By TotalDeathCount desc

--death counts by continent
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount --cast max deaths as integer to fix issue with variable type
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order By TotalDeathCount desc

--below not correct, but used for purposes of drill down in tableau (in tutorial https://www.youtube.com/watch?v=qfyynHBFOsM&t=101s)
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount --cast max deaths as integer to fix issue with variable type
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order By TotalDeathCount desc

--drill down by continent and by location (country)
Select continent, location, MAX(cast(Total_deaths as int)) as TotalDeathCount --cast max deaths as integer to fix issue with variable type
From PortfolioProject..CovidDeaths
Group by continent, location
Order By continent, TotalDeathCount desc

--global numbers
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
Group By date
Order By 1,2

--remove date, look at total cases overall across the world
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
Order By 1,2

--Join covid deaths and covid vaccinations tables
Select *
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.iso_code = 'GRD' --check to make sure the two tables joined correctly, check location and date (both show up twice in new joined table)

--Total population vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--rolling count of new-vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) 
as rollingTotalVaccinations
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--and dea.date > '2021-01-12'
--and dea.location = 'Albania'
order by 2,3

--new column total new vaccinations per population...cannot use new columns to create additional columns must create a temporary column or CTE
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) 
as rollingTotalVaccinations--, (rollingTotalVaccinations/population)*100
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Use CTE
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, rollingTotalVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) 
as rollingTotalVaccinations--, (rollingTotalVaccinations/population)*100
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and dea.location = 'Albania'
and dea.date > '2021-01-12'
--order by 2,3
)
Select *, (rollingTotalVaccinations/Population)*100 as vaccinationsPerPerson
From PopVsVac

--As of 2021-04-30, 12% of Albania's population is vaccinated.

--Use a Temp table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rollingTotalVaccinations numeric
)


Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) 
as rollingTotalVaccinations--, (rollingTotalVaccinations/population)*100
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (rollingTotalVaccinations/Population)*100 as vaccinationsPerPerson
From #PercentPopulationVaccinated

--Create a View
If OBJECT_ID ('VaccinationsPerPerson', 'V') is not null
DROP View VaccinationsPerPerson

Create View VaccinationsPerPerson as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) 
as rollingTotalVaccinations
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

--Query a View to use for visualization later
Select *
From VaccinationsPerPerson

SELECT DB_NAME() AS DataBaseName --should be PortfolioProject, but it says 'Master'. Issue with View not showing up in the project.
