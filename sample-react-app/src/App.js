import React from "react";import Header from "./components/header/header";import Counter from "./components/counter/counter";
export default function App() {
  return (
    <div>
      <Header title="FilmCast Pro" />
      <Counter initialCount={0} />
      <p>Welcome to the app!</p>
    </div>
  );
}