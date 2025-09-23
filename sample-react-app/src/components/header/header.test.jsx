import React from "react";import { render, screen } from "@testing-library/react";import Header from "./header";
describe("Header Component", () => {
  test("renders with default title", () => {
    render(<Header />);
    expect(screen.getByTestId("header-title")).toHaveTextContent("My App");
  });

  test("renders with a custom title", () => {
    render(<Header title="FilmCast Pro" />);
    expect(screen.getByTestId("header-title")).toHaveTextContent("FilmCast Pro");
  });
});