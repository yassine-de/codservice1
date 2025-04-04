/*
  # Create users and orders tables

  1. New Tables
    - `users`
      - `id` (serial, primary key) - Auto-incrementing user identifier
      - `name` (text) - User's full name
      - `email` (text, unique) - User's email address
      - `password` (text) - User's password
      - `phone` (text) - User's phone number
      - `role` (integer) - User's role (1: Admin, 2: Staff, 3: Seller)
      - `is_active` (boolean) - Account status
      - `created_at` (timestamp) - Account creation date

    - `orders`
      - `id` (serial, primary key) - Auto-incrementing order identifier
      - `user_id` (integer) - References users(id)
      - `total_amount` (decimal) - Total order amount
      - `status` (integer) - Order status
      - `shipping_address` (text) - Delivery address
      - `phone` (text) - Contact phone
      - `notes` (text) - Additional notes
      - `created_at` (timestamp) - Order creation date
      - `updated_at` (timestamp) - Last update date

  2. Security
    - Enable RLS on both tables
    - Add appropriate policies for data access
*/

-- Create users table with auto-incrementing ID
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  password text NOT NULL,
  phone text,
  role integer NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Create orders table with reference to users
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  user_id integer NOT NULL,
  total_amount decimal(10,2) NOT NULL DEFAULT 0.00,
  status integer NOT NULL DEFAULT 1,
  shipping_address text NOT NULL,
  phone text NOT NULL,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Create policies for users
CREATE POLICY "Users can read own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid()::integer);

-- Create policies for orders
CREATE POLICY "Users can view their own orders"
  ON orders
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::integer);

CREATE POLICY "Users can create orders"
  ON orders
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid()::integer);

CREATE POLICY "Users can update their own orders"
  ON orders
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::integer)
  WITH CHECK (user_id = auth.uid()::integer);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert test users
INSERT INTO users (name, email, password, role, phone, is_active)
VALUES 
  ('Admin User', 'admin@codservice.com', 'start123', 1, '+1234567890', true),
  ('Staff User', 'staff@codservice.com', 'start123', 2, '+1234567891', true),
  ('Seller User', 'seller@codservice.com', 'start123', 3, '+1234567892', true);