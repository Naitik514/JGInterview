USE [JGBS_Dev]
GO
/****** Object:  StoredProcedure [dbo].[USP_CheckUserName]    Script Date: 23-12-2016 10:19:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified By : Jaylem , Date : 23-Dec-2016
-- =============================================
ALTER PROCEDURE [dbo].[USP_CheckUserName] 
(
	@Login_Id varchar(50) = '',
	@Phone varchar(50) = ''
)
AS
BEGIN

	SELECT * FROM tblInstallUsers 
	WHERE Email Is Not Null And Email != ''
	And Phone Is Not Null And Phone != ''
	And (Email = @Login_Id OR Phone = @Phone)

END

GO

-- =============================================
-- Author:		Jaylem
-- Create date: 23-Dec-2016
-- =============================================
CREATE TABLE [dbo].[tblUserOTP](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[OTP] [nvarchar](6) NULL,
	[ExpireDateTime] [datetime] NULL,
	[UserID] [int] NULL,
	[UserType] [int] NULL,
	[CreatedDate] [datetime] NULL,
 CONSTRAINT [PK_tblUserOTP] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


GO
-- =============================================
-- Author:		Jaylem
-- Create date: 23-Dec-2016
-- Description:	Save OTP
-- =============================================
CREATE PROCEDURE InsertUserOTP
	  @OTP As nvarchar(6),
      @UserID As int,
      @UserType int,
	  @result int out
AS
BEGIN

	set @result =0;

	Declare @ExpireDateTime DateTime
	Set @ExpireDateTime = DateAdd(Day,1,GetDate())

	UPDATE [tblUserOTP]
	SET [ExpireDateTime] = GetDate()
	WHERE [UserID] = @UserID And [UserType] = @UserType And [ExpireDateTime] > GetDate()

	INSERT INTO [tblUserOTP]([OTP],[ExpireDateTime],[UserID],[UserType],[CreatedDate])
	VALUES(@OTP,@ExpireDateTime,@UserID,@UserType,GetDate())

	set @result = 1;
	return @result

END
GO
