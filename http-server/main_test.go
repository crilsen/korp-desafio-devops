package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestProjetoKorpGet(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/projeto-korp", nil)
	rec := httptest.NewRecorder()

	projetoKorp(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	var resposta resposta
	if err := json.NewDecoder(rec.Body).Decode(&resposta); err != nil {
		t.Fatalf("decodificar resposta: %v", err)
	}
	if resposta.Nome != "Projeto Korp" {
		t.Fatalf("nome = %q", resposta.Nome)
	}
	if _, err := time.Parse(time.RFC3339, resposta.Horario); err != nil {
		t.Fatalf("horário não é RFC3339: %v", err)
	}
}

func TestProjetoKorpRejeitaMetodoDiferenteDeGet(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/projeto-korp", nil)
	rec := httptest.NewRecorder()

	projetoKorp(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}
	if allow := rec.Header().Get("Allow"); allow != http.MethodGet {
		t.Fatalf("Allow = %q, want %q", allow, http.MethodGet)
	}
}
