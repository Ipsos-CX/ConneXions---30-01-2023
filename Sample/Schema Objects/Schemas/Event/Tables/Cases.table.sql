CREATE TABLE [Event].[Cases] (
    [CaseID]           dbo.CaseID         NOT NULL,
    [CaseStatusTypeID] dbo.CaseStatusTypeID       NOT NULL,
    [CreationDate]     DATETIME2       NOT NULL,
    [ClosureDate]      DATETIME2       NULL,
    [OnlineExpiryDate] DATETIME2		NULL,
    [SelectionOutputPassword] [dbo].[SelectionOutputPassword]	 NULL,
    [AnonymityDealer] BIT NULL,
    [AnonymityManufacturer] BIT NULL
);

