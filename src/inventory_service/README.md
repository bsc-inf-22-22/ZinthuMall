ZinthuMall - Inventory Management API

 Tech Stack
The backend uses NestJS with TypeScript, PostgreSQL database, and Prisma as the ORM. Docker is optional for containerization.

Database Setup

First, create a PostgreSQL database called "zinthumall_db". Then create a .env file in your project root and add your database connection string with your PostgreSQL username and password.
After that, run the Prisma migration command to create the product and inventory transaction tables in your database.
 How to Run the Server
Install all dependencies using npm install. Then start the development server with npm run start:dev. The API will run on http://localhost:3000.
For production, first run npm run build to compile the code, then npm run start:prod to start the server.

API Routes

There are six endpoints, all starting with /inventory:
- GET /inventory - Gets all products with their current stock levels
- GET /inventory/low-stock - Gets products with less than 5 units in stock
- GET /inventory/out-of-stock - Gets products with zero stock
- POST /inventory/add-stock - Adds stock to a product (requires productId and quantity in the request body)
- POST /inventory/reduce-stock - Reduces stock for customer orders or adjustments
- GET /inventory/history/productId - Shows all stock changes for a specific product

Response Examples

When you request all inventory using GET /inventory, you'll receive an array of products showing their ID, product ID, name, quantity in stock, and stock status (IN_STOCK, LOW_STOCK, or OUT_OF_STOCK).
When adding stock with POST /inventory/add-stock, you send a product ID and quantity. The response confirms success and shows the updated product with its new stock quantity.
When reducing stock with POST /inventory/reduce-stock, you send a product ID and quantity. The response confirms success and shows the updated product. If there isn't enough stock, you'll receive an error message saying "Insufficient stock".
When checking low stock products, you'll receive a list of products with less than 5 units remaining.
When viewing transaction history, you'll see the product name, current stock, and a list of all past stock changes including quantities, transaction types (STOCK_IN, STOCK_OUT, or SALE), dates, and any notes.

 Docker Setup

If you want to use Docker, first build the image using the docker build command. Then run the container using docker run, making sure to pass your .env file. Alternatively, you can use docker-compose up -d to start both the application and PostgreSQL together.

Useful Commands

You can open Prisma Studio (a database GUI) using npx prisma studio to view and edit data visually.
If you need to reset your database, use npx prisma migrate reset (this will delete all your data).
If Prisma acts up, regenerate the client with npx prisma generate.

Testing with cURL

You can test the API using cURL commands. For example, GET requests can be tested by simply visiting the URL in your browser or using curl. For POST requests, you'll need to send JSON data with the content-type header set to application/json.

Troubleshooting

If you get database connection errors, make sure PostgreSQL is running on your computer. On Windows, you can check with the "pg_isready" command.
If you get Prisma errors, try regenerating the Prisma client. If port 3000 is already in use, you can either stop the program using that port or change the port number in the main.ts file.

