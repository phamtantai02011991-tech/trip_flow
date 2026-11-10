using System.Reflection;
using TripFlow.Tests.Fixtures;

namespace TripFlow.Tests;

public class TestRunner
{
    public static async Task<int> Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        Console.WriteLine("================================================================");
        Console.WriteLine(" TRIPFLOW .NET 10 - IN-PROCESS XUNIT PARITY TEST RUNNER");
        Console.WriteLine("================================================================");

        using var factory = new TestWebApplicationFactory();
        var testClasses = new[]
        {
            typeof(AuthParityTests),
            typeof(CatalogParityTests),
            typeof(PlacesAndCorridorTests),
            typeof(TripsAndExpensesTests),
            typeof(AdminParityTests),
            typeof(SmokeTestRunner)
        };

        int total = 0;
        int passed = 0;
        int failed = 0;

        foreach (var testClass in testClasses)
        {
            Console.WriteLine($"\n[SUITE] {testClass.Name}:");
            object? instance = null;
            try
            {
                instance = Activator.CreateInstance(testClass, factory);
            }
            catch (Exception ex)
            {
                var inner = ex.InnerException ?? ex;
                Console.WriteLine($"  [ERROR] Cannot instantiate {testClass.Name}: {inner.GetType().Name} - {inner.Message}\n{inner.StackTrace}");
                continue;
            }

            var methods = testClass.GetMethods(BindingFlags.Public | BindingFlags.Instance)
                .Where(m => m.GetCustomAttribute<FactAttribute>() != null)
                .OrderBy(m => m.Name);

            foreach (var m in methods)
            {
                total++;
                var sw = System.Diagnostics.Stopwatch.StartNew();
                try
                {
                    var result = m.Invoke(instance, null);
                    if (result is Task t)
                    {
                        await t;
                    }
                    sw.Stop();
                    passed++;
                    Console.WriteLine($"  [PASS] {m.Name} ({sw.ElapsedMilliseconds} ms)");
                }
                catch (Exception ex)
                {
                    sw.Stop();
                    failed++;
                    var inner = ex.InnerException ?? ex;
                    Console.WriteLine($"  [FAIL] {m.Name} ({sw.ElapsedMilliseconds} ms)");
                    Console.WriteLine($"         Error: {inner.GetType().Name}: {inner.Message}");
                }
            }
        }

        Console.WriteLine("\n================================================================");
        Console.WriteLine($" KẾT QUẢ KIỂM THỬ: {passed}/{total} PASS ({failed} FAIL)");
        Console.WriteLine("================================================================");

        return failed == 0 ? 0 : 1;
    }
}
