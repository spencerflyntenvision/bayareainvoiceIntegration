USE [RAMP_ENTERPRISE]
GO
/****** Object:  StoredProcedure [dbo].[rampnetsuiteintegrationBayArea]    Script Date: 11/15/2024 8:10:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[rampnetsuiteintegrationBayArea]
	-- Add the parameters for the stored procedure here	


AS
BEGIN
			;WITH BayAreacharges AS (
     --manual invoice query
	 select 
    distinct
    '' AS HEADER_MEMO
    , concat('UCS-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , InvoiceDate as INVOICE_DATE
    , PONumber as PO_NUM --need to figure out where this is set 
    , '' as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , id.GLCode as ITEM_EXTERNAL_ID
    , isnull(id.tariffname, id.AccessorialName) as ITEM_NAME 
    , id.InvoicedQty as Quantity
    , id.Rate as Rate 
    , id.Amount as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , '' as CASE_COUNT 
    , '' as DESCRIPTION 
    , '860' as Location
    , id.RenewalDate
    ,ih.Status
    ,ih.EditWho
	,ih.CreateDate as SYSTEM_CREATED_AT
    from invoice ih 
        left join InvoiceDetail id on ih.InvoiceNumber = id.InvoiceNumber
        join customer c on ih.CustomerName = c.CustomerName
        where 
		 ih.invoicetype = 5
			AND ih.status = '80' 
			AND ih.EditWho = 'Mule-IP'
			and ih.facilityname = 'Oakland' 	
			
	union
select 
    distinct
    '' AS HEADER_MEMO
    , concat('UCS-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , InvoiceDate as INVOICE_DATE
    , PONumber as PO_NUM --need to figure out where this is set 
    , '' as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , id.GLCode as ITEM_EXTERNAL_ID
    , isnull(id.tariffname, id.AccessorialName) as ITEM_NAME 
    , id.InvoicedQty as Quantity
    , id.Rate as Rate 
    , id.Amount as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , id.InvoiceLineNumber as CASE_COUNT 
    , concat('Lot:', isnull(id.warehouselotreference, id.WarehouseLot)
    , '/Item:' , id.warehouseSKU
    , case when id.GLCode in ('UCS-IT-RSTO') then 
    concat('/Storage Period: ', cast(id.RenewalDate as date),' - ',cast(DATEADD(Day, case 
        when 1=1 then 30 
    else 0 end, renewaldate) as date))
    else null end 
    ) as DESCRIPTION 
    , '860' as Location
    , id.RenewalDate
    ,ih.Status
    ,ih.EditWho
	,ih.CreateDate as SYSTEM_CREATED_AT
    from invoice ih 
        join InvoiceDetail id on ih.InvoiceNumber = id.InvoiceNumber
        join customer c on ih.CustomerName = c.CustomerName
        where isnull(id.glcode, '!') in ('UCS-IT-RSTO')
		and ih.invoicetype in (4)
			AND ih.status = '80' 
			AND ih.EditWho = 'Mule-IP'
			and ih.facilityname = 'Oakland' 		
			union
			--Receipt query

			
    select 
    '' AS HEADER_MEMO	
    , concat('UCS-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , ih.InvoiceDate as INVOICE_DATE
    , isnull(isnull(ih.PONumber, isnull(r.CustomerOrderNumber, so.CustomerOrderNumber)),'') as PO_NUM
    , isnull(so.CustomerOrderNumber,r.CustomerOrderNumber) as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , did.GLCode as ITEM_EXTERNAL_ID
    , isnull(did.AccessorialName, did.TariffName) as ITEM_NAME --do I need to add tarriff here? 
    , sum(did.InvoicedQty) as Quantity
    , did.Rate as Rate 
    , sum(did.Amount) as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , '' as CASE_COUNT 
    ,concat('Item:', did.WarehouseSku,'/Lot:', did.WarehouseLot, '/Case Count Total:', r.QtyReceived, '/Activity Date:', cast(r.DeliveryDate as date)) as DESCRIPTION 
    , '860' as Location
    , '' as renewaldate 
    ,ih.Status
    , ih.EditWho
	, ih.CreateDate as SYSTEM_CREATED_AT	
    from invoice ih 		         
		join documentinvoice di on di.documentinvoicenumber = IH.DocumentInvoiceNumber
		join DocumentInvoiceDetail did on did.InvoiceNumber = ih.InvoiceNumber and did.CustomerName = ih.CustomerName 
		join customer c on ih.CustomerName = c.CustomerName
		left join warehousereceipt r on r.ReceiptNumber = di.ReceiptNumber and r.facilityname = 'Oakland' 
		left join ShipmentOrder SO on SO.OrderNumber = di.OrderNumber and so.facilityname = 'Oakland'
    where 
		ih.status = '80' 
		AND ih.EditWho = 'Mule-IP'
	    and ih.facilityname = 'Oakland' 
		and ih.invoicetype in (1,2)
    group by
    ih.InvoiceNumber
    ,so.CustomerPONumber
	,so.CustomerOrderNumber
	,r.CustomerPONumber
	,r.ShipmentId
	,r.CustomerOrderNumber
	,c.User2
	, so.OrderNumber
	, r.ReceiptNumber
    ,ih.CustomerName
    ,ih.CreateDate
    ,ih.InvoiceDate
    ,did.GLCode
    ,did.AccessorialName
    , did.Rate
    , did.WarehouseLot
    , did.WarehouseSku
    , c.User1
    , did.TariffName
    , ih.Status
    , ih.EditWho
	, did.warehouselotreference
	, did.CreateWho
	, ih.PONumber
	, r.QtyReceived
	, r.DeliveryDate
	
)
SELECT *
FROM BayAreacharges
WHERE Location = '860' 

END





