-- Covid 19 Data Exploration 

select *
from PortfolioProject..CovidDeaths$
where continent is not null
order by 3,4


-- Data we are going to use

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
where continent is not null
order by 1,2

-- total cases vs total deaths
-- likelihood of dying if you contract Covid by country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathRate
from PortfolioProject..CovidDeaths$
where continent is not null
order by 1,2

-- total cases vs population
-- percentage of population infected with Covid

select location, date, population, total_cases, (total_cases/population)*100 as percentInfected
from PortfolioProject..CovidDeaths$
--where location like '%states%'
order by 1,2

-- highest infection rate by country compared to its population 

select location, population, max(total_cases) as highestInfectionCount, max((total_cases/population))*100 as percentInfected
from PortfolioProject..CovidDeaths$
--where location like '%states%'
group by location, population
order by 4 desc

-- highest death rate by country

select location, max(cast(total_deaths as bigint)) as totalDeathCount--, --max((total_deaths/total_cases))*100 as deathRate
from PortfolioProject..CovidDeaths$
where continent is not null
--where location like '%states%'
group by location
order by totalDeathCount desc

-- highest death rate by continent

select continent, max(cast(total_deaths as int)) as totalDeathCount
from PortfolioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null 
group by continent
order by totalDeathCount desc

--select location, max(cast(total_deaths as int)) as totalDeathCount
--from PortfolioProject..CovidDeaths$
--where continent is null
----where location like '%states%'
--group by location
--order by totalDeathCount desc

-- global numbers

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/SUM(new_cases)*100 as deathRate
from PortfolioProject..CovidDeaths$
where continent is not null
--group by date
order by 1,2

-- total population vs vaccinations
-- percentage of population that has received at least one Covid vaccine

-- using cte to perform calculation on partition

with PopvsVac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
--(rollingPeopleVaccinated/dea.population)*100
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (rollingPeopleVaccinated/population)*100
from PopvsVac

-- using temp table to perform calculation on partition
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
--(rollingPeopleVaccinated/dea.population)*100
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3

select *, (rollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated

-- view to store data

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
--(rollingPeopleVaccinated/dea.population)*100
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 1,2,3

select *
from PercentPopulationVaccinated 