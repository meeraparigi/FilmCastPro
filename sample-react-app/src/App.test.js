import React from "react";import { render, screen } from "@testing-library/react";import App from "./App";
describe("App Component", () => {
  test("renders the header title", () => {
    render(<App />);
    expect(screen.getByText(/FilmCast Pro/i)).toBeInTheDocument();
  });
});