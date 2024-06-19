IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'PR3')
BEGIN
    DROP PROCEDURE PR3;
END;
GO

CREATE PROCEDURE PR3 
    @Email NVARCHAR(256), 
    @CodCourse INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @TutorId UNIQUEIDENTIFIER;
    DECLARE @ProfileId INT;
    DECLARE @Credits INT;
    DECLARE @CreditsRequired INT;

    BEGIN TRANSACTION;

    -- Obtener el ID del usuario 
    SELECT @UserId = Id
    FROM proyecto1.Usuarios
    WHERE Email = @Email;

    -- Obtener el ProfileId del usuario
    SELECT @ProfileId = Id
    FROM proyecto1.ProfileStudent
    WHERE UserId = @UserId;

    -- Obtener los créditos actuales
    SELECT @Credits = Credits
    FROM proyecto1.ProfileStudent
    WHERE Id = @ProfileId;

    -- Obtener los créditos requeridos del curso
    SELECT @CreditsRequired = CreditsRequired
    FROM proyecto1.Course
    WHERE CodCourse = @CodCourse;

    -- Verificar si el usuario tiene suficientes créditos para el curso
    IF @Credits >= @CreditsRequired
    BEGIN
        -- Insertar en la tabla CourseAssignment
        INSERT INTO BD2.proyecto1.CourseAssignment (StudentId, CourseCodCourse)
        VALUES (@UserId, @CodCourse);

        -- Notificar al estudiante
        INSERT INTO BD2.proyecto1.Notification (UserId, Message, Date)
        VALUES (@UserId, 'Has sido asignado al curso', GETDATE());

        -- Obtener el TutorId para el curso
        SELECT @TutorId = TutorId 
        FROM BD2.proyecto1.CourseTutor 
        WHERE CourseCodCourse = @CodCourse;

        -- Notificar al tutor
        INSERT INTO BD2.proyecto1.Notification (UserId, Message, Date)
        VALUES (@TutorId, 'Un nuevo alumno ha sido asignado a tu curso', GETDATE());
    END
    ELSE
    BEGIN
        -- Notificar al estudiante que no tiene suficientes créditos
        INSERT INTO BD2.proyecto1.Notification (UserId, Message, Date)
        VALUES (@UserId, 'No cuentas con creditos suficientes para asignarte este curso', GETDATE());
    END

    COMMIT TRANSACTION;
END;
GO



IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'PR2')
BEGIN
    DROP PROCEDURE PR2;
END;
GO

CREATE PROCEDURE PR2 
    @Email NVARCHAR(256), 
    @CodCourse INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @RoleId UNIQUEIDENTIFIER;
    DECLARE @TutorCode NVARCHAR(50);  -- Ajusta el tamaño del tipo de datos según corresponda

    -- Obtener el ID del usuario y verificar que el email esté confirmado
    SELECT @UserId = Id
    FROM proyecto1.Usuarios
    WHERE Email = @Email AND EmailConfirmed = 1;

    IF @UserId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('El usuario no existe o no tiene una cuenta activa.', 16, 1);
        RETURN;
    END

    -- Obtener el RoleId para el rol de Tutor
    SELECT @RoleId = Id 
    FROM proyecto1.Roles 
    WHERE RoleName = 'Tutor';

    -- Asegurar que RoleId no es NULL
    IF @RoleId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR ('El rol de Tutor no existe.', 16, 1);
        RETURN;
    END

    -- Generar un código único para el tutor
    SET @TutorCode = NEWID();

    -- Añadir el rol de tutor al usuario
    INSERT INTO proyecto1.UsuarioRole (UserId, RoleId, IsLatestVersion)
    VALUES (@UserId, @RoleId, 1);  -- Aseguramos que IsLatestVersion tenga un valor predeterminado

    -- Crear el perfil de tutor
    INSERT INTO proyecto1.TutorProfile (UserId, TutorCode)
    VALUES (@UserId, @TutorCode);  -- Aseguramos que TutorCode no sea nulo

    -- Asignar el curso al tutor
    INSERT INTO proyecto1.CourseTutor (CourseCodCourse, TutorId)
    VALUES (@CodCourse, @UserId);

    -- Notificar al usuario
    INSERT INTO proyecto1.Notification (UserId, Message, Date)
    VALUES (@UserId, 'Has sido promovido al rol de tutor.', GETDATE());

    COMMIT TRANSACTION;
END;
GO



-- Crear la función dbo.F4
CREATE FUNCTION dbo.F4()
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM proyecto1.HistoryLog
);
GO

-- Ejecutar la función dbo.F4
SELECT * FROM dbo.F4();

CREATE FUNCTION dbo.Func_tutor_course(@TutorId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
(
    SELECT c.CodCourse, c.Name
    FROM proyecto1.Course c
    JOIN proyecto1.CourseTutor ct ON c.CodCourse = ct.CourseCodCourse
    WHERE ct.TutorId = @TutorId
);



-- Crear la función dbo.F2
CREATE FUNCTION dbo.F2(@Id INT)
RETURNS TABLE
AS
RETURN	
(
    SELECT c.CodCourse, c.Name
    FROM proyecto1.Course c
    JOIN proyecto1.CourseTutor ct ON c.CodCourse = ct.CourseCodCourse
    JOIN proyecto1.TutorProfile tp ON ct.TutorId = tp.UserId
    WHERE tp.Id = @Id
);







-- Ejecutar la función dbo.F2
SELECT * FROM dbo.F2(1);

-- Ejecutar la función dbo.Func_tutor_course
SELECT * FROM dbo.Func_tutor_course('D2459BF7-78D7-4B64-B2AB-CD98382F8FE4');

-- Ejecutar el procedimiento almacenado PR3
EXEC PR3 @Email = 'juan.perez@example.com', @CodCourse = 772;

-- Ejecutar el procedimiento almacenado PR2
EXEC PR2 @Email = 'maria.gonzalez@example.com', @CodCourse = 970;


INSERT INTO [BD2].[proyecto1].[Usuarios] 
  ([Id], [Firstname], [Lastname], [Email], [DateOfBirth], [Password], [LastChanges], [EmailConfirmed])
VALUES 
  (NEWID(), 'Juan', 'Pérez', 'juan.perez@example.com', '1990-01-15', 'password123', GETDATE(), 1),
  (NEWID(), 'María', 'González', 'maria.gonzalez@example.com', '1992-05-21', 'password123', GETDATE(), 1),
  (NEWID(), 'Carlos', 'Rodríguez', 'carlos.rodriguez@example.com', '1988-11-30', 'password123', GETDATE(), 1),
  (NEWID(), 'Ana', 'Martínez', 'ana.martinez@example.com', '1995-07-14', 'password123', GETDATE(), 1),
  (NEWID(), 'Luis', 'Fernández', 'luis.fernandez@example.com', '1993-03-05', 'password123', GETDATE(), 1);


INSERT INTO BD2.proyecto1.TutorProfile (UserId, TutorCode)
VALUES 
  ('D2459BF7-78D7-4B64-B2AB-CD98382F8FE4', '100');


INSERT INTO BD2.proyecto1.CourseTutor (TutorId, CourseCodCourse)
VALUES 
  ('D2459BF7-78D7-4B64-B2AB-CD98382F8FE4', 772);