create database Insurance_Analytics;
use Insurance_Analytics;

select count(*) from brokerage;
select * from brokerage;
desc brokerage;

UPDATE brokerage
SET income_due_date = NULL
WHERE income_due_date = '';

alter table brokerage
modify policy_start_date Date,
modify policy_end_date Date,
modify income_due_date Date,
modify last_updated_date Date;

UPDATE brokerage
SET amount = NULL
WHERE amount = '';

ALTER TABLE brokerage
MODIFY amount DECIMAL(15,2);

# Brokerage Cleaning and converting done

desc budget;
select * from budget;

alter table budget
modify `Cross sell bugdet` decimal(15,2),
modify `New Budget` decimal(15,2),
modify `Renewal Budget` decimal(15,2);

# Budget Cleaning and converting done

desc fees;
select * from fees;

alter table fees
modify income_due_date Date;

alter table fees
modify Amount decimal(15,2);

# Fees Cleaning and converting done

desc invoice;
select * from invoice;

alter table invoice
modify income_due_date date,
modify amount Decimal(15,2),
modify ï»¿invoice_number int,
modify invoice_date date;

# Invoice Cleaning and converting done

desc meeting;
select * from meeting;

alter table meeting
modify meeting_date Date;

# Meeting Cleaning and converting done

desc opportunity;
select * from opportunity;

alter table opportunity
modify premium_amount decimal(15,2),
modify revenue_amount decimal(15,2),
modify closing_date date;

# Opportunity Cleaning and converting done

SELECT SUM(amount)
FROM brokerage;


# KPIs

-- (1) Target (Cross sell, New, Renewal)
select `ï»¿Branch`,sum(`New Budget`) as New_Target,
               sum(`Cross sell bugdet`) as Cross_Sell_Target,
               Sum(`Renewal Budget`) as Renewal_Target from Budget
group By `ï»¿Branch`;
         
-- (2) Achieved (Cross sell, New, Renewal)
select income_class, sum(Amount) as Achieved
from ( select income_class, Amount from brokerage
     union all
     select income_class, Amount from fees
) As total_Placed
group by income_class;

-- (3) New-Invoice (Cross sell, New, Renewal)
select Branch_name,
	   sum(case when income_class = "Cross Sell" then Amount else 0 end) as Cross_Sell_New,
       sum( case when income_class = "New" then Amount else 0 end) as New_NewInvoive,
       sum(case when income_class = "Renewal" then Amount else 0 end) as Renewal_New
from Invoice
Group by branch_name;

#OR 

-- Cross Sell,New,Renewal wise Target,Achieved,Invoice (Combined)

select t.income_class, t.target,
    coalesce(a.achieved, 0) as achieved,
    coalesce(i.invoice_total, 0) as invoice
from (select 'cross sell' as income_class, sum(`Cross sell bugdet`) as target from Budget
	union all
select 'new' as income_class, sum(`New Budget`) as target from budget
	union all
select 'renewal' as income_class, sum(`Renewal Budget`) as target from budget) t
left join 
(select income_class,sum(fees_amount + brokerage_amount) as achieved
	from(select income_class, sum(fees.amount) as fees_amount, 0 as brokerage_amount from fees
group by income_class
	union all 
select income_class,0, sum(brokerage.amount) from brokerage
group by income_class) x group by income_class) a
on t.income_class = a.income_class
left join 
(select income_class,sum(invoice.amount) as invoice_total from invoice
group by income_class) i on t.income_class = i.income_class;

-- (4) Cross Placed achievement %
select concat(Round(((coalesce((select sum(amount) from brokerage 
                     where income_class = "Cross Sell"),0))
    + (coalesce((select sum(amount)from fees 
                    where income_class = "Cross Sell"),0)))
     / Nullif((select sum(`Cross sell bugdet`) from budget),0) * 100, 2),"%") as Cross_plcd_achvmnt;

#OR

SELECT ROUND((placed.total_placed / budget.total_budget) * 100,2) AS cross_Plcd_achievement
FROM (SELECT SUM(Amount) AS total_placed
    FROM ( SELECT Amount FROM brokerage WHERE income_class='Cross Sell'
        UNION ALL
        SELECT Amount FROM fees WHERE income_class='Cross Sell') t ) placed
        JOIN
     ( SELECT SUM(`Cross sell bugdet`) AS total_budget FROM budget) budget;

-- (5) Cross Sell Invoice achievement %
select Round((coalesce((select sum(amount) from invoice where income_class = "Cross Sell"),0))
 / (coalesce((select sum(`Cross sell bugdet`) from budget),0)) * 100, 2) as Cross_Invoice_Achvmnt;

-- (6) New Placed achievement %
select concat(Round(((coalesce((select sum(amount) from brokerage 
                     where income_class = "New"),0))
    + (coalesce((select sum(amount)from fees 
                    where income_class = "New"),0)))
     / Nullif((select sum(`New Budget`) from budget),0) * 100, 2),"%") as New_plcd_achvmnt;
     
-- (7) New Invoice achievement %
select Round((coalesce((select sum(amount) from invoice where income_class = "New"),0))
 / (coalesce((select sum(`New Budget`) from budget),0)) * 100, 2) as New_Invoice_Achvmnt;
     
-- (8) Renewal Placed achievement %
select concat(Round(((coalesce((select sum(amount) from brokerage 
                     where income_class = "Renewal"),0))
    + (coalesce((select sum(amount)from fees 
                    where income_class = "Renewal"),0)))
     / Nullif((select sum(`Renewal Budget`) from budget),0) * 100, 2),"%") as Renewal_plcd_achvmnt;

-- (9) Renewal Invoice achievement % 
select Round((coalesce((select sum(amount) from invoice where income_class = "Renewal"),0))
 / (coalesce((select sum(`Renewal Budget`) from budget),0)) * 100, 2) as Renewal_Invoice_Achvmnt;

-- (10) Yearly Meeting Count
select year(meeting_date) as Year, count(meeting_date) as Yearly_Meeting_Count from meeting
group by year(meeting_date);

-- (11) No. Meetings by Account Executive
select `Account Executive`, count(meeting_date) as Meeting_Count from meeting
group by `Account Executive`
order by Meeting_Count desc;

-- (12) No. of Invoice by Account Executive
select `Account Executive`, count(`ï»¿invoice_number`) as Invoice_Count from invoice
group by `Account Executive`
order by Invoice_Count desc;

#OR

SELECT `Account Executive`,
    count(CASE WHEN income_class = 'Cross Sell' THEN 1 END) AS cross_sell_total,
    count(CASE WHEN income_class = 'New' THEN 1 END) AS new_total,
	count(CASE WHEN income_class = 'Renewal' THEN 1 END) AS renewal_total,
    count(*) AS total_invoice FROM invoice
GROUP BY `Account Executive`
ORDER BY total_invoice DESC;

-- (13) Stage by Total Revenue
select stage, sum(revenue_amount) as Total_Revenue from opportunity
group by stage
order by Total_Revenue desc;

-- (14) Total Opportunity
select count(opportunity_id) as Total_Opportunities from opportunity;

-- (15) Total Open Opprotunity
select count(opportunity_id) as Total_Open_Opportunities from opportunity
where stage In ('Qualify Opportunity','Propose Solution');

-- (16) Top 4 Open Oppertunity by Revenue
select `ï»¿opportunity_name`, sum(revenue_amount) as Revenue from opportunity
group by `ï»¿opportunity_name`
order by Revenue desc
limit 4;

-- (17) Opportunity Product Distribution
select product_group, count(*) as Total_Opportunity from opportunity
group by product_group;
#OR
select product_group, count(revenue_amount) as Total_Opportunity from opportunity
group by product_group;

-- (18) Average Deal Size
select Product_group, round(avg(revenue_amount),2) as Avg_Deal_Size from opportunity
group by product_group;

