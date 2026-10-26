import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import App from './App.tsx';

describe('App Component', () => {
    it('renders the welcome heading and platform status', () => {
        render(<App />);
        expect(screen.getByRole('heading', { name: /Welcome to Anony/i })).toBeInTheDocument();
        expect(screen.getByText(/Zero-PII Anonymous Identity Engine Active/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /Get Started/i })).toBeInTheDocument();
    });
});
