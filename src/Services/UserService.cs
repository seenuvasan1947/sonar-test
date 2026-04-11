using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;

namespace MyApp.Services
{
    // BUG: Class too complex, multiple issues
    public class UserService
    {
        // BUG: Hardcoded connection string with credentials
        private string connectionString = "Server=localhost;Database=mydb;User Id=admin;Password=admin123;";
        
        // BUG: Public field
        public int UserCount;
        
        // BUG: Method with SQL injection vulnerability
        public void GetUserById(string userId)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                // BUG: SQL injection - string concatenation in query
                var query = "SELECT * FROM Users WHERE Id = '" + userId + "'";
                var command = new SqlCommand(query, connection);
                connection.Open();
                command.ExecuteNonQuery();
            }
        }
        
        // BUG: Method with no error handling
        public void DeleteUser(int userId)
        {
            // BUG: Direct file deletion without validation
            File.Delete($"C:\\Users\\{userId}.dat");
            
            // BUG: Console.WriteLine instead of proper logging
            Console.WriteLine("User deleted: " + userId);
        }
        
        // BUG: Unused private method
        private string FormatName(string firstName, string lastName)
        {
            var middleName = "Unknown"; // BUG: Unused variable
            return firstName + " " + lastName;
        }
        
        // BUG: Method returning null instead of empty collection
        public List<string> GetAllUsers()
        {
            return null; // BUG: Should return empty list instead of null
        }
        
        // BUG: Duplicate code in multiple methods
        public void SaveUser(string name, string email)
        {
            Console.WriteLine("Validating user...");
            if (string.IsNullOrEmpty(name))
            {
                Console.WriteLine("Name is required");
                return;
            }
            if (string.IsNullOrEmpty(email))
            {
                Console.WriteLine("Email is required");
                return;
            }
            Console.WriteLine("Saving user...");
        }
        
        public void UpdateUser(string name, string email)
        {
            Console.WriteLine("Validating user..."); // BUG: Duplicate code
            if (string.IsNullOrEmpty(name))
            {
                Console.WriteLine("Name is required"); // BUG: Duplicate code
                return;
            }
            if (string.IsNullOrEmpty(email))
            {
                Console.WriteLine("Email is required"); // BUG: Duplicate code
                return;
            }
            Console.WriteLine("Updating user...");
        }
    }
}
