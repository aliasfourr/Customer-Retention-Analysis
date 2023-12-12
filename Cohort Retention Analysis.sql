--- inspecting and cleaning the data set 
-- initial total records = 541909
-- the number of null customerid rows = 135080
SELECT  [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
  FROM [Cohort Retention Analysis].[dbo].[Online Retail - Copy]
  where    CustomerID is not null
  -- selecting non null records
  -- total records 406829
  with clean_customerid_coherant_analysus as 
  (
  select * 
   FROM [Cohort Retention Analysis].[dbo].[Online Retail - Copy]
  where CustomerID is not null
  )
 , clean_quantity_uniteprice as 
  (

 select * 
  from clean_customerid_coherant_analysus
  where Quantity > 0 
        and UnitPrice > 0
		
		)
-- the number of total records after rmoving 8960 negative quantitys is 397884 
-- their was no negative unite prices 

-- cheaking duplicated 
,duplicate_data as (
select * , ROW_NUMBER() over(
partition by [InvoiceNo]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
	  ,[Country]
	  order by customerid 
) as alike_rows
from clean_quantity_uniteprice
)
select * 
into #clean_online_retail
from duplicate_data
where alike_rows=1
--the number of records changed from 397884 to 392649 after removing duplicated data 
-- 5235 duplicated records was removed 

-- we cleaned the data 
-- coharent analysis
select * 
from #clean_online_retail
---parametars we need for cohort_rate
--1 unique identifier (Customerid)
--2 initial start date as  (first invoice date)
--3 revenue data 

-- when was the first time a customer specific made a pershase 
select 
distinct customerid
,min(invoicedate) as first_purshase_date 
,DATEFROMPARTS(year(min(invoicedate)),MONTH(min(invoicedate)),1) as retation_initial_date 
into #cohort
from #clean_online_retail
group by customerid
-- creating cohort index (number of months passed seins first purshase)



select sss.*
, cohort_index = year_diff*12 + month_diff +1
into #customer_retention
from 
(
select ss.*
,year_diff = invoice_year-retation_year
,month_diff = invoice_month-reatation_month
from 
(
select cln.*
,coh.retation_initial_date 
,year(cln.Invoicedate) as invoice_year
,month(cln.Invoicedate) as invoice_month
,year(retation_initial_date) as retation_year
,month(retation_initial_date) as reatation_month

from  #clean_online_retail as cln
left join #cohort as coh
on cln.customerid = coh.CustomerID
    ) as ss
) as sss

-- pivot data to see cohort table 
select *
into #retention_table
from (
select distinct customerid
,cohort_index
,retation_initial_date
from #customer_retention
) as tb
pivot(
count(customerid)
for cohort_index in 
(
 [1],
 [2],
 [3],
[4],
[5],
[6],
[7],
[8],
[9],
[10],
[11],
[12],
[13]
)
) as pivot_cohort
order by retation_initial_date

--final
--reteion rate numbers by month 
select *  
from #retention_table
order by retation_initial_date


--final
--reteion rate percentage by month 
select retation_initial_date
,(1.0 * [1]/[1]) * 100 as [1]
,(1.0*[2]/[1])*100 as [2]
,(1.0*[3]/[1])*100 as [3]
,(1.0*[4]/[1])*100 as [4]
,(1.0*[5]/[1])*100 as [5]
,(1.0*[6]/[1])*100 as [6]
,(1.0*[7]/[1])*100 as [7]
,(1.0*[8]/[1])*100 as [8]
,(1.0*[9]/[1])*100 as [9]
,(1.0*[10]/[1])*100 as [10]
,(1.0*[11]/[1])*100 as [11]
,(1.0*[12]/[1])*100 as [12]
,(1.0*[13]/[1])*100 as [13]

from #retention_table
order by retation_initial_date

