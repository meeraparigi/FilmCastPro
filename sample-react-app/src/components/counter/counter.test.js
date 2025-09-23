import React from "react";import { render, screen } from "@testing-library/react";import userEvent from "@testing-library/user-event";import Counter from "./counter";
describe("Counter Component", () => {
  test("renders with initial count", () => {
    render(<Counter initialCount={5} />);
    expect(screen.getByTestId("count")).toHaveTextContent("Count: 5");
  });
  test("increments the count when Increment button is clicked", async () => {
    render(<Counter initialCount={0} />);
    const incrementButton = screen.getByText(/increment/i);
    await userEvent.click(incrementButton);
    expect(screen.getByTestId("count")).toHaveTextContent("Count: 1");
  });
  test("decrements the count when Decrement button is clicked", async () => {
    render(<Counter initialCount={2} />);
    const decrementButton = screen.getByText(/decrement/i);
    await userEvent.click(decrementButton);
    expect(screen.getByTestId("count")).toHaveTextContent("Count: 1");
  });
  test("resets the count when Reset button is clicked", async () => {
    render(<Counter initialCount={3} />);
    const incrementButton = screen.getByText(/increment/i);
    const resetButton = screen.getByText(/reset/i);
    await userEvent.click(incrementButton);
    await userEvent.click(resetButton);
    expect(screen.getByTestId("count")).toHaveTextContent("Count: 3");
  });
});
