import { render, screen } from '@testing-library/react'
import App from './App'

test('renders conversion form', () => {
  render(<App />)
  expect(screen.getByText('Convert')).toBeInTheDocument()
})
