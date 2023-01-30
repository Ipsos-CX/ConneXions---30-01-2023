CREATE TABLE [CRM].[ResponseStatuses]
(
    ResponseStatusID				[int] IDENTITY(1,1) NOT NULL,
    ResponseStatus					VARCHAR(20) NOT NULL,
    ResponseStatusCRMOutputValue	VARCHAR(50) NOT NULL,
    Precedence						INT	NOT NULL
);
