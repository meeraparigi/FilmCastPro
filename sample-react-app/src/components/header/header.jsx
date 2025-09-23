import React from "react";
export default function Header({ title = "My App" }) {
  return <h1 data-testid="header-title">{title}</h1>;
}