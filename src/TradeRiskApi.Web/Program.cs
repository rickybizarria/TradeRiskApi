using TradeRiskApi.Application.HealthChecks;
using TradeRiskApi.Application.Services;
using TradeRiskApi.Application.Validators;
using TradeRiskApi.Domain.Interfaces;
using TradeRiskApi.Web.Middleware;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Swagger/OpenAPI configuration
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Trade Risk Classification API",
        Version = "v2.0",
        Description = "API REST para classificação automática de risco de operações financeiras (trades)",
        Contact = new OpenApiContact
        {
            Name = "UBS Technology Team",
            Email = "dev@ubs.com"
        }
    });

    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

// FluentValidation
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<TradeRequestValidator>();

// Dependency Injection
builder.Services.AddScoped<IRiskClassificationService, RiskClassificationService>();
builder.Services.AddScoped<IRiskAnalysisService, RiskAnalysisService>();

// Health Checks
builder.Services.AddHealthChecks()
    .AddCheck<RiskClassificationHealthCheck>("risk-classification");

// Logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Trade Risk API v2.0");
        c.RoutePrefix = string.Empty;
    });
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

public partial class Program { }