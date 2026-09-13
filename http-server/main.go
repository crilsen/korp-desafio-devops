package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// resposta é o payload que devolvemos no /projeto-korp
type resposta struct {
	Nome    string `json:"nome"`
	Horario string `json:"horario"`
}

var (
	// requisicoesTotais conta toda request que passa pelo handler.
	// o rótulo "path" ajuda a saber qual rota está sendo mais usada.
	requisicoesTotais = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_server_requisicoes_total",
			Help: "Quantidade total de requisições recebidas pelo serviço",
		},
		[]string{"path"},
	)

	// servicoAtivo indica se o serviço está de pé (1) ou fora (0).
	// é a forma mais simples de expor disponibilidade.
	servicoAtivo = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "http_server_ativo",
			Help: "Indica se o serviço está disponível (1 = sim, 0 = não)",
		},
	)
)

func init() {
	// registra tudo antes de começar a servir
	prometheus.MustRegister(requisicoesTotais)
	prometheus.MustRegister(servicoAtivo)
}

// comLog é um middleware simples que registra cada request no stdout.
// Essas linhas viram log no Docker e depois vão pro Loki via Promtail.
func comLog(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		inicio := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(inicio))
	})
}

// projetoKorp responde o endpoint principal, montando o horário na hora da chamada.
func projetoKorp(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.Header().Set("Allow", http.MethodGet)
		http.Error(w, "método não permitido", http.StatusMethodNotAllowed)
		return
	}

	requisicoesTotais.WithLabelValues(r.URL.Path).Inc()

	// usa UTC pra não depender do fuso de quem está rodando
	dados := resposta{
		Nome:    "Projeto Korp",
		Horario: time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(dados); err != nil {
		log.Printf("erro ao escrever resposta: %v", err)
	}
}

func main() {
	// sobe a flag de disponibilidade assim que o processo inicia
	servicoAtivo.Set(1)

	mux := http.NewServeMux()
	mux.HandleFunc("/projeto-korp", projetoKorp)
	// expõe as métricas no padrão do Prometheus
	mux.Handle("/metrics", promhttp.Handler())

	log.Println("subindo o serviço na porta 8080")
	servidor := &http.Server{
		Addr:              ":8080",
		Handler:           comLog(mux),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	if err := servidor.ListenAndServe(); err != nil {
		log.Fatalf("falha ao iniciar o servidor: %v", err)
	}
}
