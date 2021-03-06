
ALTER PROCEDURE [dbo].[UDP_CUSTOMERLOGIN]
(
	@Email varchar(100) = '',
	@Password varchar(20) = ''
)
AS
BEGIN

	SELECT * FROM new_customer 
	WHERE (Email = @Email AND Password = @Password AND Email != 'noEmail@blankemail.com') 
	OR (CellPh = @Email AND Password = @Password)

END

GO

CREATE PROCEDURE [dbo].[USP_GetCustomerNameByPhoneNumber]
(
	@Phone varchar(20) = ''
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Email FROM new_customer
	WHERE CellPh = @Phone

END

GO

CREATE PROCEDURE [dbo].[USP_GetCustomerPassword]
(
 @Login_Id varchar(50) = ''
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Password
	FROM [dbo].[new_customer]
	WHERE Email = @Login_Id OR CellPh = @Login_Id 

END