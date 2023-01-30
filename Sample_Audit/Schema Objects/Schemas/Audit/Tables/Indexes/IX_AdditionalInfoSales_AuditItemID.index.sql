CREATE NONCLUSTERED INDEX [IX_AdditionalInfoSales_AuditItemID]
ON [Audit].[AdditionalInfoSales] ([AuditItemID])
INCLUDE ([TypeOfSaleOrig],[LostLead_DateOfLeadCreation])


