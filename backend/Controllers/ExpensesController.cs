using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Data;
using TripFlow.Api.Models.DTOs;
using TripFlow.Api.Models.Entities;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/trips/{trip_id}")]
public class ExpensesController : ControllerBase
{
    private readonly TripFlowDbContext _db;

    public ExpensesController(TripFlowDbContext db)
    {
        _db = db;
    }

    [HttpGet("expenses")]
    public async Task<IActionResult> ListExpenses(int trip_id)
    {
        var expenses = await _db.Expenses
            .AsNoTracking()
            .Where(e => e.TripId == trip_id)
            .OrderByDescending(e => e.CreatedAt)
            .Select(e => new ExpenseDto
            {
                Id = e.Id,
                TripId = e.TripId,
                TripDayId = e.TripDayId,
                Category = e.Category,
                Title = e.Title,
                Amount = e.Amount,
                Planned = e.Planned,
                SpentAt = e.SpentAt,
                PaidBy = e.PaidBy,
                Note = e.Note,
                CreatedAt = e.CreatedAt
            })
            .ToListAsync();

        return Ok(expenses);
    }

    [HttpPost("expenses")]
    public async Task<IActionResult> AddExpense(int trip_id, [FromBody] ExpenseCreateRequest req)
    {
        var trip = await _db.Trips.FindAsync(trip_id);
        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        var expense = new Expense
        {
            TripId = trip.Id,
            TripDayId = req.TripDayId,
            Category = req.Category ?? "other",
            Title = req.Title.Trim(),
            Amount = req.Amount,
            Planned = req.Planned,
            SpentAt = req.SpentAt ?? DateTime.UtcNow,
            PaidBy = req.PaidBy,
            Note = req.Note,
            CreatedAt = DateTime.UtcNow
        };

        _db.Expenses.Add(expense);
        trip.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(new ExpenseDto
        {
            Id = expense.Id,
            TripId = expense.TripId,
            TripDayId = expense.TripDayId,
            Category = expense.Category,
            Title = expense.Title,
            Amount = expense.Amount,
            Planned = expense.Planned,
            SpentAt = expense.SpentAt,
            PaidBy = expense.PaidBy,
            Note = expense.Note,
            CreatedAt = expense.CreatedAt
        });
    }

    [HttpPut("expenses/{expense_id}")]
    public async Task<IActionResult> UpdateExpense(int trip_id, int expense_id, [FromBody] ExpenseUpdateRequest req)
    {
        var expense = await _db.Expenses.FirstOrDefaultAsync(e => e.Id == expense_id && e.TripId == trip_id);
        if (expense == null) return NotFound(new ErrorEnvelope("Khoản chi không tồn tại."));

        if (!string.IsNullOrWhiteSpace(req.Title)) expense.Title = req.Title.Trim();
        if (!string.IsNullOrWhiteSpace(req.Category)) expense.Category = req.Category;
        if (req.Amount.HasValue) expense.Amount = req.Amount.Value;
        if (req.Planned.HasValue) expense.Planned = req.Planned.Value;
        if (req.SpentAt.HasValue) expense.SpentAt = req.SpentAt.Value;
        if (req.PaidBy != null) expense.PaidBy = req.PaidBy;
        if (req.Note != null) expense.Note = req.Note;
        if (req.TripDayId.HasValue) expense.TripDayId = req.TripDayId.Value;

        await _db.SaveChangesAsync();

        return Ok(new ExpenseDto
        {
            Id = expense.Id,
            TripId = expense.TripId,
            TripDayId = expense.TripDayId,
            Category = expense.Category,
            Title = expense.Title,
            Amount = expense.Amount,
            Planned = expense.Planned,
            SpentAt = expense.SpentAt,
            PaidBy = expense.PaidBy,
            Note = expense.Note,
            CreatedAt = expense.CreatedAt
        });
    }

    [HttpDelete("expenses/{expense_id}")]
    public async Task<IActionResult> DeleteExpense(int trip_id, int expense_id)
    {
        var expense = await _db.Expenses.FirstOrDefaultAsync(e => e.Id == expense_id && e.TripId == trip_id);
        if (expense == null) return NotFound(new ErrorEnvelope("Khoản chi không tồn tại."));

        _db.Expenses.Remove(expense);
        await _db.SaveChangesAsync();

        return Ok(new StatusResponse { Status = "ok", Message = "Đã xóa khoản chi." });
    }

    [HttpGet("budget-summary")]
    public async Task<IActionResult> BudgetSummary(int trip_id)
    {
        var trip = await _db.Trips.Include(t => t.Expenses).FirstOrDefaultAsync(t => t.Id == trip_id);
        if (trip == null) return NotFound(new ErrorEnvelope("Chuyến đi không tồn tại."));

        int totalSpent = trip.Expenses.Sum(e => e.Amount);
        var catGroup = trip.Expenses
            .GroupBy(e => e.Category)
            .ToDictionary(g => g.Key, g => g.Sum(e => e.Amount));

        return Ok(new BudgetSummaryResponse
        {
            BudgetAmount = trip.BudgetAmount ?? 0,
            TotalSpent = totalSpent,
            Categories = catGroup
        });
    }
}
