CREATE TRIGGER [Audit].[TR_IU_Audit_PostalAddresses]
   ON [Audit].[PostalAddresses]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

    -- RECALCULATE THE AddressChecksum VALUE
    
    UPDATE PA
    SET PA.AddressChecksum = dbo.udfGenerateAddressChecksum(I.BuildingName, I.SubStreetNumber, I.SubStreet, I.StreetNumber, I.Street, I.SubLocality, I.Locality, I.Town, I.Region, I.PostCode, I.CountryID)
    FROM Audit.PostalAddresses PA
    INNER JOIN INSERTED I ON I.AuditItemID = PA.AuditItemID
    INNER JOIN DELETED D ON D.AuditItemID = I.AuditItemID
    WHERE ISNULL(I.AddressChecksum, 0) = ISNULL(D.AddressChecksum, 0) -- WHERE WE'RE NOT SPECIFICALLY SETTING THE AddressChecksum VALUE, I.E. WHERE AddressChecksum IN THE INSERTED TABLE IS NOT DIFFERENT TO THE VALUE ALREADY THERE
    

END