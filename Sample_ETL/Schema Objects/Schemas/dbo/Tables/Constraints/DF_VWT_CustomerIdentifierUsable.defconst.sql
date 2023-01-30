ALTER TABLE [dbo].[VWT]
    ADD CONSTRAINT [DF_VWT_CustomerIdentifierUsable] DEFAULT (0) FOR [CustomerIdentifierUsable];

